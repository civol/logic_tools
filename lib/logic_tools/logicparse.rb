########################################################
#     Parse a string and convert to a logic tree       #
########################################################

# For parsing the inputs
require 'parslet'

# For building logic tress
require "logic_tools/logictree.rb"






module LogicTools

    ## The parser of logic expressions.
    class Parser < Parslet::Parser

        # True / false
        rule(:tru) { str("1") }
        rule(:fal) { str("0") }
        # Variable
        # rule(:var) { match('[A-Za-uw-z]') }
        rule(:var) do
            match('[A-Za-z]') |
            str("{") >> ( match('[0-9A-Za-z]').repeat ) >> str("}")
        end
        # And operator
        # rule(:andop) { str("&&") | match('[&\.\*^]') }
        rule(:andop) { str(".") }
        # Or operator
        # rule(:orop) { match('[+|v]') }
        rule(:orop) { str("+") }
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


    ## The logic tree generator from the syntax tree.
    class Transform < Parslet::Transform

        # Terminal rules
        rule(:tru => simple(:tru)) { NodeTrue.new() }
        rule(:fal => simple(:fal)) { NodeFalse.new() }
        rule(:var => simple(:var)) do
            name = var.to_s
            name = name[1..-2] if name.size > 1 # Remove the {} if any.
            NodeVar.new(name)
        end
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


    ## The parser/gerator main fuction: converts the text in +str+ to a 
    #  logic tree.
    def string2logic(str)
        # Remove the spaces
        str = str.gsub(/\s+/, "")
        # Parse the string
        return Transform.new.apply(Parser.new.parse(str))
    end

end
