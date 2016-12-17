#!/usr/bin/env ruby
##############################################################
# Convert a logic expression to its conjunctive normal form  #
##############################################################


# For building logic tress
require "logic_tools/logictree.rb"

# For parsing the inputs
require "logic_tools/logicparse.rb"

# For the command line interface
require "logic_tools/logicinput.rb"

include LogicTools





############################
# The main program

## Now use the common command line interface
# # First gets the expression to treat
# $expr = nil
# # Is it in the arguments?
# unless $*.empty? then
#     # Yes, get the expression from them
#     $expr = $*.join
# else
#     # Get the expression from standard input
#     print "Please enter your expression and end with ^D:\n"
#     $expr = ARGF.read
# end
# 
# # Parse the expression
# $parsed = string2logic($expr)
# 
# # Generates its disjunctive normal form
# $dij = $parsed.to_std_disjunctive
# 
# # print "Computation done\n"
# 
# # Display the result
# print $dij.to_s, "\n"


# Iterrate on each expression
each_input do |expr|
    # Parse the expression
    parsed = string2logic(expr)

    # Generates its disjunctive normal form
    dij = parsed.to_std_disjunctive

    # print "Computation done\n"

    # Display the result
    print dij.to_s, "\n"
end
