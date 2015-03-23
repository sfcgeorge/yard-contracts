# FIXME: YARD is broken for named arguments in Ruby 2.2, the problem is with
# a Ripper regression in the standard library! Very annoying.
# To use YARD you must downgrade to 2.1 temporarily until 2.2 is patched.
# https://github.com/lsegal/yard/issues/825
require 'yard'

require 'contracts/formatters'
require 'contracts/builtin_contracts'
require 'yard-contracts/formatters'

# Run the custom handler by supplying the file to yard with the -e flag, e.g.
#
# bundle exec yardoc -e /Users/sfcgeorge/.rbenv/versions/2.1.5/lib/ruby/gems/2.1.0/gems/contracts-0.7/lib/yard_extensions.rb
#
# NOTE: There must be a nicer way to specify that... a YARD plugin seems to be
# a gem beginning with `yard-` e.g. `yard-contracts` so it looks like we can't
# have the extension within the main contracts gem. Thoughts?
#module YARD::Handlers::Ruby::Contracts
class ContractHandler < YARD::Handlers::Ruby::Base
  handles method_call(:Contract)
  namespace_only #only match method calls inside a namespace not inside a method

  def process
    # statement is a YARD attribute, subclassing YARD::Parser::Ruby::AstNode
    # Here it's class will be YARD::Parser::Ruby::MethodCallNode
    # MethodCallNode#line_range returns the lines the method call was over
    # AstNode#line gives the first line of the node
    # AstNode#traverse takes a block and yields child nodes
    # AstNode#jump returns the first node matching type, otherwise returns self

    # Go up the tree to namespace level, then jump to next def statement
    # Note: this won't document dynamicly defined methods.
    parent = statement.parent
    contract_last_line = statement.line_range.last
    #YARD::Parser::Ruby::MethodDefinitionNode
    def_method_ast = parent.traverse do |node|
      # Find the first def statement that comes after the contract we're on
      break node if node.line > contract_last_line && node.def?
    end

    ## Hacky way to test for class methods
    ## TODO: What about module methods? Probably broken.
    scope = def_method_ast.source.match(/ self\./) ? :class : :instance
    name = def_method_ast.method_name true
    params = def_method_ast.parameters #YARD::Parser::Ruby::ParameterNode
    contracts = statement.parameters #YARD::Parser::Ruby::AstNode

    ret = YARDContracts::Formatters::ParamContracts.new(params, contracts).return
    params = YARDContracts::Formatters::ParamContracts.new(params, contracts).params
    docstring = YARD::DocstringParser.new.parse(statement.docstring).to_docstring

    # Merge params into provided docstring otherwise there can be duplicates
    docstring.tags(:param).each do |tag|
      param = params.find{ |t| t[0].to_s == tag.name.to_s }
      if param
        params.delete(param)
        tag.types ||= []
        tag.types << param[1].inspect
        tag.text = "#{param[2].empty? ? '' : "#{param[2]}. "}#{tag.text}"
      end
    end
    # If the docstring didn't contain all of the params already add the rest
    params.each do |param|
      docstring.add_tag(
        YARD::Tags::Tag.new(:param, param[2].to_s, param[1].inspect, param[0])
      )
    end

    # Merge return into provided docstring otherwise there can be a duplicate
    # NOTE: Think about what to do with multiple returns
    if (tag = docstring.tag(:return))
      tag.types ||= []
      tag.types << ret[0].inspect
      tag.text = "#{ret[1].empty? ? '' : "#{ret[1]}. "}#{tag.text}"
    else
      # If the docstring didn't contain a return already add it
      docstring.add_tag(
        YARD::Tags::Tag.new(:return, ret[1].to_s, ret[0].inspect)
      )
    end

    # YARD hasn't got to the def method yet, so we create a stub of it with
    # our docstring, when YARD gets to it properly it will fill in the rest.
    YARD::CodeObjects::MethodObject.new(namespace, name, scope) do |o|
      o.docstring = docstring
    end
    # No `register()` it breaks stuff! Above implicit return value is enough.
  end
end
#end
