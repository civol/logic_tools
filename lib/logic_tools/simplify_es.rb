#!/usr/bin/env ruby
#########################################################################
#      Simplifies a logic expression using the ESPRESSO algorithm       #
#########################################################################


# For building logic trees
require "logic_tools/logictree.rb"

# For parsing the inputs
require "logic_tools/logicparse.rb"

# For simplifying with the ESPRESSO method.
require "logic_tools/logicsimplify_es.rb"

# For the command line interface
require "logic_tools/logicinput.rb"

include LogicTools





############################
# The main program

# Iterrate on each expression
each_input do |expr|
    # Parse the expression
    parsed = string2logic(expr)

    # Simplify it
    simple = parsed.simplify
    # print "Computation done\n"
 
    # Display the result
    print simple.to_s, "\n"
end
