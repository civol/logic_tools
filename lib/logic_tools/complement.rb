#!/usr/bin/env ruby
#########################################################################
#         Computes (quickly) the complement of a logic expression       #
#########################################################################


# For building logic trees
require "logic_tools/logictree.rb"

# For parsing the inputs
require "logic_tools/logicparse.rb"

# For converting the inputs to covers.
require "logic_tools/logicconvert.rb"

# For processing the cover (and therfore check tautology)
require "logic_tools/logiccover.rb"

# For the command line interface
require "logic_tools/logicinput.rb"

include LogicTools





############################
# The main program

# Iterrate on each expression
each_input do |expr|
    # Parse the expression.
    parsed = string2logic(expr)
    # print "parsed=#{parsed}\n"

    # Convert it to a cover.
    cover = parsed.to_cover
    # print "cover=#{cover}\n"

    # Computes the complement
    complement = cover.complement
    # print "complement=#{complement}\n"
 
    # Display the result
    print complement.to_tree, "\n"
end
