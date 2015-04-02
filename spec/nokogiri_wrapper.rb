require 'nokogiri'

class DocDoc
  def initialize(doc); @doc = doc; end
end

class DocModule < DocDoc
  def find_method(instance=:instance, name)
    DocMethod.new(
      @doc.at_css("##{instance}_method_details")
          .at_css("##{name}-#{instance}_method")
          .parent
    )
  end

  class DocMethod < DocDoc
    def discussion
      @doc.at_css('.discussion')
    end

    def params
      @doc.at_css('ul.param')
    end

    def param(param)
      params.at_css("li:contains('#{param}')")
    end

    def return
      @doc.at_css('ul.return li')
    end
  end
end
