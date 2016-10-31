##########################
# Truth table generator  #
##########################

# For parsing the inputs
require 'parslet'

# For building logic tress
require "logic_tools/logictree.rb"




########################################################
# Parse a string and convert to a logic tree


module LogicTools

    ## The parser of logic expressions
    class Parser < Parslet::Parser

        # True / false
        rule(:tru) { str("1") }
        rule(:fal) { str("0") }
        # Variable
        rule(:var) { match('[A-Za-uw-z]') }
        # And operator
        rule(:andop) { str("&&") | match('[&\.\*^]') }
        # Or operator
        rule(:orop) { match('[+|v]') }
        # Not operator
        rule(:notop) { match('[~!]') }

        # Grammar rules
        root(:expr)
        rule(:expr) { orexpr }
        rule(:orexpr) { (andexpr >> ( orop >> andexpr ).repeat).as(:orexpr) }
        rule(:andexpr) { (notexpr >> ( (andop >> notexpr) | notexpr ).repeat).as(:andexpr) }
        rule(:notexpr) { ((notop.as(:notop)).repeat >> term).as(:notexpr) }
        rule(:term) { tru.as(:tru) | fal.as(:fal) | var.as(:var) |
                      ( str("(") >> expr >> str(")") ) }
    end


    ## The logic tree generator from the syntax tree
    class Transform < Parslet::Transform

        # Terminal rules
        rule(:tru => simple(:tru)) { NodeTrue.new() }
        rule(:fal => simple(:fal)) { NodeFalse.new() }
        rule(:var => simple(:var)) { NodeVar.new(var) }
        rule(:notop => simple(:notop)) { "!" }

        # Not rules
        rule(:notexpr => simple(:expr)) { expr }
        rule(:notexpr => sequence(:seq)) do
            expr = seq.pop
            if seq.size.even? then
                expr
            else
                NodeNot.new(expr)
            end
        end

        # And rules
        rule(:andexpr => simple(:expr)) { expr }
        rule(:andexpr => sequence(:seq)) do
            NodeAnd.new(*seq)
        end

        # Or rules
        rule(:orexpr => simple(:expr)) { expr }
        rule(:orexpr => sequence(:seq)) do
            NodeOr.new(*seq)
        end
    end


    ## The parser/gerator main fuction: converts a string to a logic tree
    #  Param:
    #  +str+:: the string to parse
    #  Return: the resulting logic tree
    def string2logic(str)
        # Remove the spaces
        str = str.gsub(/\s+/, "")
        # Parse the string
        return Transform.new.apply(Parser.new.parse(str))
    end

end
