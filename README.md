# LogicTools

LogicTools is a set of command-line tools for processing logic expressions.
The tools include:
 * simplify\_qm:  for simplifying a logic expression.
 * std\_conj:  for computing the conjunctive normal form of a logic expression.
 * std\_dij:   for computing the disjunctive normal form a of logic expression.
 * truth\_tbl: for generating the truth table of a logic expression.

## Disclaimer

There is still a nasty bug in the logic simplifying tool (simplify_qm) which makes it give a wrong result. Fortunately, it seems to happen in some rare cases only.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logic_tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logic_tools

## Usage

LogicTools is a command line-based set of tool. Each tool is used as follows:
tool\_name "logical expression"

The logical expression is an expression where:
* a logical variable is represented by a single alphabetical character (hence there is in total 56 possible variables);
* a logical OR is represented by a '+' character;
* a logical AND is represented by a '.' character (but it can be omitted);
* a logical NOT is represented by a '~' or a '!' character;
* opening and closing parenthesis are represented by, respectively, '(' and ')' characters.

Important notice: 
* the priority among logical operators is as follows: NOT > AND > OR
* logical expressions must be put between quotes (the '"' character).

For instance the followings are valid logical expression using the a,b and c variables:
"ab+ac"
"a.b.c"
"a+b+!c"
"a~(b+~c)"

Finally, here are a few examples of LogicTool usage:
* simplifying the expression a+ab:
simplify\_qm "a+ab"
-> a
* compute the conjunctive normal form of the expression a+ab:
std\_conj "a+ab"
-> ab+a~b
* compute the disjunctive normal form of the expression a+ab:
std\_dij "a+ab"
-> (a+b)(a+~b)
* compute the truth table of the expression a+ab:
truth\_tbl "a+ab"
-> a b
   0 0 0
   0 1 0
   1 0 1
   1 1 1

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/civol/logic\_tools.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## To do
### High priority
* Fix the bug that makes simplify\_qm produce sometimes a wrong result. 
* Downgrade the user interface: actually the interface can do much more than what is described in the documentation, but this is not really useful, so it should better to remove these features.

### Low priority

* Add a more efficient alternative command to simplify_qm, based on the Espresso algorithm for example.


