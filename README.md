# LogicTools

LogicTools is a set of command-line tools for processing logic expressions.
The tools include:

 * __simplify\_qm__:  for simplifying a logic expression.
 * __simplify\_es__:  for simplifying a logic expression (much more efficient than simplify_qm).
 * __std\_conj__:  for computing the conjunctive normal form of a logic expression.
 * __std\_dij__:   for computing the disjunctive normal form a of logic expression.
 * __truth\_tbl__: for generating the truth table of a logic expression.
 * __is\_tautolofy__: for checking if a logic expression is a tautology or not.
 * __complement__: for computing the complement of a logic expression.


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

LogicTools is a command line-based set of tool. Each tool is used as follows for processing a single expression:

    $ tool_name "single logical expression"

Multiple expressions stored into a file can also be processed as follows:

    $ tool_name -f <filename>

The logical expression is an expression where:

* a logical variable is represented by a single alphabetical character (hence there is in total 56 possible variables), or a string of alphabetical characters enclosed by curly brackets.
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
    "{foo}+{bar}"

Finally, here are a few examples of LogicTool usage:

* simplifying the expression a+ab:

        $ simplify_qm "a+ab"
        -> a
* compute the conjunctive normal form of the expression a+ab:

        $ std_conj "a+ab"
        -> ab+a~b

* compute the disjunctive normal form of the expression a+ab:

        $ std_dij "a+ab"
        -> (a+b)(a+~b)

* compute the truth table of the expression a+ab:

        $ truth_tbl "a+ab"
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
* Update the code of simplify_qm so that it uses the optimized LogicTool::Cover class and minimal\_column\_covers methods.


