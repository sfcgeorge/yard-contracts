module Contracts
  class Stringy
    def self.valid?(val)
      Or[String, Symbol].valid? val
    end

    def self.to_s
      'A String or Symbol'
    end
  end
end

class Plural
  def self.valid?(val)
    val.is_a?(String) && val[-1] == 's'
  end

  def self.to_s
    "A plural String ending in 's'"
  end
end
