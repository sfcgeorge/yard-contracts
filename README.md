# yard-contracts

[![Gem Version](https://badge.fury.io/rb/yard-contracts.svg)](http://badge.fury.io/rb/yard-contracts)
[![Code Climate](https://codeclimate.com/github/sfcgeorge/yard-contracts/badges/gpa.svg)](https://codeclimate.com/github/sfcgeorge/yard-contracts)
[![Build Status](https://travis-ci.org/sfcgeorge/yard-contracts.svg?branch=master)](https://travis-ci.org/sfcgeorge/yard-contracts)
[![Inline docs](http://inch-ci.org/github/sfcgeorge/yard-contracts.svg?branch=master)](http://inch-ci.org/github/sfcgeorge/yard-contracts)
[![Join the chat at https://gitter.im/egonSchiele/contracts.ruby](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/egonSchiele/contracts.ruby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

yard-contracts is a YARD plugin that works with the fantastic Contracts gem to automatically document types and descriptions of parameters in your method signatures, saving time, making your code concise and keeping your documentation consistent.

Have you ever got fed up of coding validations, writing error messages and then documenting those things? All this duplication and boilerplate code has always bugged me. Contracts solves the validations and error messages part already, turning many lines of repetitive code into 1 terse readable one. This extension now solves the documentation part making documentation automatically say the same as your validations.

* Types gleaned from Contract and automatically linked with the method signature then added to param documentation.
* to_s is called on the types and where it is useful, added to the param documentation as the description.
* If any params are already documented manually, the extra information from the Contract is merged in rather than overriding or duplicating; allowing full flexibility.

I've used this plugin gem on an existing project and documented 69 methods; it seems to be working great! Note I haven't used all corners of YARD, so there may be advanced features or scenarios that this doesn't work for, please open an issue if you find one. For straightforward projects, however, it's fantastic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yard-contracts'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yard-contracts

Compatible with MRI Ruby 2.0+ and JRuby 1.9mode (with additional kramdown gem).

## Examples

See these two equivalent(ish) examples and be blown away.

Before Contracts and yard-contracts:

```ruby
# Find the root of a number, like `Math.sqrt` for arbitrary roots.
# @param root [Numeric] Root must be greater than zero.
# @param num [Numeric] Can't take root of a negative number.
# @return [Numeric] Result will be greater than zero.
def root(root, num) 
  unless root.is_a?(Numeric) && root > 0
    raise "root must be Numeric and > 0."
  end
  unless num.is_a?(Numeric) && num >= 0
    raise "num must be Numeric and >= 0."
  end

  result = num**(1.0/root)

  unless result.is_a?(Numeric) && result >= 0
    raise "return wasn't Numeric or >= 0."
  end

  return result
end
```

After:

```ruby
# Find the root of a number, like `Math.sqrt` for arbitrary roots.
# @param num Can't take root of a negative number.
Contract Pos, Nat => Nat
def root(root, num) 
  num**(1.0/root)
end
```

Isn't that nicer? In the above after example, `@param root ...` and `@return ...` are automatically added to the documentation with their type and no description was deemed necessary. The `num` param has a manual documentation description, that automatically has it's type merged in. This gives you the flexibility to document parameters as explicitly as you like with the minimum of duplication.

There is another option for adding more detailed parameter descriptions without duplication of the parameter name or the problem of keeping documentation in sync across methods... and it's already built into Contracts: custom type classes with `to_s`! The above example would be a bad place to do this as there's only one method, but imagine your project had lots of methods that calculate roots on numbers or pass those numbers around---you'd end up duplicating the documentation for the `num` parameter. Instead add a custom type class `Rootable` or more explicitly `RootableNum` if you prefer:

```ruby
class Rootable
  def self.valid? val
    Nat.valid? val
  end

  def self.to_s
    "(Nat) Can't take root of a negative number."
  end
end

# Find the root of a number, like `Math.sqrt` for arbitrary roots.
Contract Pos, Rootable => Rootable
def root(root, num) 
  num**(1.0/root)
end
```

Wow, the code and docstring is now as terse as possible with no duplication at all. Documentation generated will include the type and custom description as before, and now `Rootable` can be used all throughout the project making everything concise and clear. Plus, run time errors will have the same description from `Rootable` making it easier to debug as your documentation matches your errors. Perfect.

For yard-contracts to pick up these custom type classes they you need to supply the path to the file they are defined in to YARD with the -e flag, and they must be defined directly under the Contracts namespace or the global namespace.

See Contracts for more information on creating custom type classes.

## Usage

YARD needs to be made aware of this plugin. Simply give it to YARD with the --plugin flag:

```
bundle exec yardoc --plugin contracts
```

If you have defined custom type classes, they need to be given to YARD as well. First they must be specified in the global namespace or directly under the Contracts namespace. Give YARD the path to your custom contracts with the -e flag:

```
bundle exec yardoc --plugin contracts -e lib/my_project/custom_contracts.rb
```

If using a local fork of yard-contracts you can specify your path to `yard_extensions.rb` with the -e flag instead.

```
bundle exec yardoc -e path/to/lib/yard_extensions.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Open issues, and if you can please send pull requests:

1. Fork it ( https://github.com/sfcgeorge/yard-contracts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
