# FIXME: YARD is broken for named arguments in Ruby 2.2, the problem is with
# a Ripper regression in the standard library! Very annoying.
# To use YARD you must downgrade to 2.1 temporarily until 2.2 is patched.
# https://github.com/lsegal/yard/issues/825
require 'yard'

# require 'contracts/formatters'
require 'contracts/builtin_contracts'
require 'yard-contracts/formatters'

# Run the plugin handler by supplying it to yard with the --plugin flag
#
# @example
#   bundle exec yardoc --plugin contracts
class ContractHandler < YARD::Handlers::Ruby::Base
  handles method_call(:Contract)
  namespace_only # only match calls inside a namespace not inside a method

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
    # YARD::Parser::Ruby::MethodDefinitionNode
    def_method_ast = parent.traverse do |node|
      # Find the first def statement that comes after the contract we're on
      break node if node.line > contract_last_line && node.def?
    end

    ## Hacky way to test for class methods
    ## TODO: What about module methods? Probably broken.
    scope = def_method_ast.source.match(/def +self\./) ? :class : :instance
    name = def_method_ast.method_name true
    params = def_method_ast.parameters # YARD::Parser::Ruby::ParameterNode
    contracts = statement.parameters # YARD::Parser::Ruby::AstNode

    ret = Contracts::Formatters::ParamContracts.new(params, contracts).return
    params = Contracts::Formatters::ParamContracts.new(params, contracts).params
    doc = YARD::DocstringParser.new.parse(statement.docstring).to_docstring

    process_params(doc, params)
    process_return(doc, ret)

    # YARD hasn't got to the def method yet, so we create a stub of it with
    # our docstring, when YARD gets to it properly it will fill in the rest.
    YARD::CodeObjects::MethodObject.new(namespace, name, scope) do |o|
      o.docstring = doc
    end
    # No `register()` it breaks stuff! Above implicit return value is enough.
  end

  def process_params(doc, params)
    merge_params(doc, params)
    new_params(doc, params)
  end

  def merge_params(doc, params)
    # Merge params into provided docstring otherwise there can be duplicates
    doc.tags(:param).each do |tag|
      next unless (param = params.find { |t| t[0].to_s == tag.name.to_s })
      params.delete(param)
      set_tag(tag, param[1], param[2])
    end
  end

  def new_params(doc, params)
    # If the docstring didn't contain all of the params already add the rest
    params.each do |param|
      doc.add_tag(
        YARD::Tags::Tag.new(:param, param[2].to_s, param[1].inspect, param[0])
      )
    end
  end

  def process_return(doc, ret)
    if (tag = doc.tag :return)
      # Merge return into provided docstring otherwise there can be a duplicate
      merge_return(tag, ret)
    else
      # If the docstring didn't contain a return already add it
      new_return(doc, ret)
    end
  end

  def merge_return(tag, ret)
    set_tag(tag, ret[0], ret[1])
  end

  def new_return(doc, ret)
    doc.add_tag(
      YARD::Tags::Tag.new(:return, ret[1].to_s, ret[0].inspect)
    )
  end

  def set_tag(tag, type, to_s)
    tag.types ||= []
    tag.types << type.inspect
    tag.text = tag_text(to_s, tag.text)
  end

  def tag_text(to_s, text)
    "#{to_s.empty? ? '' : "#{to_s}. "}#{text}"
  end
end
