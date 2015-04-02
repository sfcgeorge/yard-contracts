require 'spec_helper'
require 'nokogiri_wrapper'

describe YARDContracts do
  before(:context) do
    @base =
      if ENV['TRAVIS_BUILD_DIR']
        ENV['TRAVIS_BUILD_DIR']
      else
        File.expand_path('../..', File.dirname(__FILE__))
      end

    @yardir = 'yard-spec-output'
    Dir.mkdir(@yardir) unless Dir.exist? @yardir

    puts @yard_return = `bundle exec yardoc --quiet --no-highlight --no-save --no-cache --no-stats -o "#{@base}/#{@yardir}" -e "#{@base}/lib/yard-contracts.rb" -e "#{@base}/spec/yard-test/custom_contracts.rb" "#{@base}/spec/yard-test/*.rb"`

    @standard_class_doc = DocModule.new Nokogiri::HTML(
      File.read("#{@yardir}/StandardClass.html")
    )
  end

  after(:context) do
    FileUtils.remove_entry(@yardir)
  end

  it 'has a version number' do
    expect(YARDContracts::VERSION).not_to be nil
  end

  # YARD will err if the plugin isn't loaded correctly
  it 'works without YARD failure' do
    expect(@yard_return).not_to match(/error/)
  end

  # Usual discussion from docstring must be included
  it 'still has discussion' do
    expect(
      @standard_class_doc.find_method(:simple).discussion.text
    ).to match(/naming things/)
  end

  it 'annotates a param with type' do
    expect(
      @standard_class_doc.find_method(:simple).param(:one).text
    ).to match(/\(Num\)/)
  end

  it 'annotates return with type' do
    expect(
      @standard_class_doc.find_method(:simple).return.text
    ).to match(/\(String\)/)
  end

  it 'doesnt include useless/duplicate to_s description' do
    expect(
      @standard_class_doc.find_method(:simple).param(:one).text
    ).to_not match(/\(Num\).*Num/)
  end

  # Checking that both the type and description are present
  it 'calls to_s on complex params' do
    ret = @standard_class_doc.find_method(:with_to_s).param(:one).text
    expect(ret).to match(/\(Or.+\)/)
    expect(ret).to match(/String or Symbol/)
  end

  it 'merges types with manual param descriptions' do
    ret = @standard_class_doc.find_method(:param_desc).param(:repeats).text
    expect(ret).to match(/\(Num\)/)
    expect(ret).to match(/times to repeat text/)
  end

  it 'merges type with manual return description' do
    ret = @standard_class_doc.find_method(:param_desc).return.text
    expect(ret).to match(/\(String\)/)
    expect(ret).to match(/repeated text/)
  end

  it 'merges manual param descriptions with to_s description' do
    ret = @standard_class_doc.find_method(:fancy_desc).param(:stringy).text
    expect(ret).to match(/\(Or.+\)/) # make sure type is still there
    expect(ret).to match(/Symbol or String/) # the to_s part
    expect(ret).to match(/what this is/) # custom description
  end

  it 'merges manual return description with to_s description' do
    ret = @standard_class_doc.find_method(:fancy_desc).return.text
    expect(ret).to match(/\(Or.+\)/)
    expect(ret).to match(/TrueClass or FalseClass/)
    expect(ret).to match(/true for String/)
  end

  it 'works for custom contracts with to_s in Contracts namespace' do
    ret = @standard_class_doc.find_method(:custom_contract).param(:word).text
    expect(ret).to match(/\(Stringy\)/)
    expect(ret).to match(/A String or Symbol/)
  end

  it 'works for custom contracts with to_s in global namespace' do
    ret = @standard_class_doc.find_method(:custom_contract).return.text
    expect(ret).to match(/\(Plural\)/)
    expect(ret).to match(/A plural String/)
  end

  it 'documents class methods from def statement' do
    expect(
      @standard_class_doc.find_method(:class, :class_simple).param(:bool).text
    ).to match(/\(Bool\)/)
  end

  it 'documents class methods from def statement with odd formatting' do
    expect(
      @standard_class_doc.find_method(:class, :class_format).param(:bool).text
    ).to match(/\(Bool\)/)
  end
end
