require 'contracts/builtin_contracts'

module Contracts
  # A namespace for classes related to formatting.
  module Formatters
    class TypesAST
      def initialize(types)
        @types = types[0..-2]
      end

      def to_a
        types = []
        @types.each_with_index do |type, i|
          if i == @types.length - 1
            # Get the param out of the `param => result` part
            types << [type.first.first.source, type.first.first]
          else
            types << [type.source, type]
          end
        end
        types
      end

      def result
        # Get the result out of the `param => result` part
        [@types.last.last.last.source, @types.last.last.last]
      end
    end

    class ParamsAST
      def initialize(params)
        @params = params
      end

      def to_a
        params = []
        @params.each do |param|
          # YARD::Parser::Ruby::AstNode
          next if param.nil?
          if param.type == :list
            param.each do |p|
              next if p.nil?
              params << build_param_element(p)
            end
          else
            params << build_param_element(param)
          end
        end
        params
      end

      private

      def build_param_element(param)
        type = param.type
        ident = param.jump(:ident, :label).last.to_sym
        [type, ident]
      end
    end

    class TypeAST
      def initialize(type)
        @type = type
      end

      # Formats any type of type.
      def type(type = @type)
        if type.type == :hash
          hash_type(type)
        elsif type.type == :array
          array_type(type)
        else
          type.source
        end
      end

      # Formats Hash type.
      def hash_type(hash)
        # Ast inherits from Array not Hash so we have to enumerate :assoc nodes
        # which are key value pairs of the Hash and build from that.
        result = {}
        hash.each do |h|
          result[h[0].jump(:label).last.to_sym] =
            Contracts::Formatters::InspectWrapper.create(type(h[1]))
        end
        result
      end

      # Formats Array type.
      def array_type(array)
        # This works because Ast inherits from Array.
        array.map do |v|
          Contracts::Formatters::InspectWrapper.create(type(v))
        end.inspect
      end
    end

    class ParamContracts
      def initialize(param_string, types_string)
        @params = ParamsAST.new(param_string).to_a
        types = TypesAST.new(types_string)
        @types = types.to_a
        @result = types.result
      end

      def params
        s = []
        i = named_count = 0
        @params.each do |param|
          param_type, param = param

          on_named = param_type == :named_arg ||
                     (named_count > 0 && param_type == :ident)
          i -= named_count if on_named

          type, type_ast = @types[i]
          con = get_contract_value(type)
          type = TypeAST.new(type_ast).type

          # Ripper has :rest_param (splat) but nothing for doublesplat,
          # it's just called :ident the same as required positional params.
          # This is really annoying. So we have to figure it out.
          if on_named
            @named_con ||= con
            @named_type ||= type
            if @named_con.is_a? Hash
              if param_type == :named_arg
                con = @named_con.delete(param)
                type = @named_type.delete(param)
              else
                con = @named_con
                type = @named_type
              end
            else
              @named_con = con = '?'
              @named_type = type = []
            end
            named_count = 1
          end

          type = Contracts::Formatters::InspectWrapper.create(type)
          desc = Contracts::Formatters::Expected.new(con, false).contract
          # The pluses are to escape things like curly brackets
          desc = "#{desc}".empty? ? '' : "+#{desc}+"
          s << [param, type, desc]
          i += 1
        end
        s
      end

      def return
        type, type_ast = @result
        con = get_contract_value(type)
        type = Contracts::Formatters::InspectWrapper.create(
          TypeAST.new(type_ast).type
        )
        desc = Contracts::Formatters::Expected.new(con, false).contract
        desc = "#{desc}".empty? ? '' : "+#{desc}+"
        [type, desc]
      end

      private

      # The contract starts as a string, but we need to get it's real value
      # so that we can call to_s on it.
      def get_contract_value(type)
        con = type
        begin
          con = Contracts.const_get(type)
        rescue Exception
          begin
            con = eval(type)
          rescue Exception
          end
        end
        con
      end
    end
  end
end
