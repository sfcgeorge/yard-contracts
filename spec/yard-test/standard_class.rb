require 'contracts'

class StandardClass
  include Contracts

  # naming things and cache invalidation
  Contract Num => String
  def simple(one)
  end

  Contract Or[String, Symbol] => Any
  def with_to_s(one)
  end

  # repeat text number of times
  # @param repeats times to repeat text
  # @return repeated text
  Contract String, Num => String
  def param_desc(text, repeats)
  end

  # Is it a String or a Symbol?
  # @param stringy determine what this is
  # @return true for String
  Contract Or[Symbol, String] => Or[TrueClass, FalseClass]
  def fancy_desc(stringy)
  end
end
