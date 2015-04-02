require 'contracts'

class StandardClass
  include Contracts

  # naming things and cache invalidation
  Contract Num => String
  def simple(one)
    self.class_simple(true)
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

  # Custom contracts will be documented (including `to_s`) if they are passed
  # to YARD with -e flag and defined under global or Contracts namespace.
  Contract Stringy => Plural
  def custom_contract(word)
  end

  # Class method
  Contract Bool => Any
  def self.class_simple(bool)
  end

  # Class method with odd formatting
  Contract Bool => Any
  def       self.class_format(bool)
  end
end
