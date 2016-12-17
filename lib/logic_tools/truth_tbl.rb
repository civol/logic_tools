#!/usr/bin/env ruby
##########################
# Truth table generator  #
##########################


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
# # Display the variables
# $vars = $parsed.getVariables
# $vars.each { |var| print "#{var} " }
# print "\n"
# 
# # Display the values
# $parsed.each_line do |vars,val|
#     vars.each { |var| print "#{var.value ? 1 : 0} " }
#     print "#{val ? 1: 0}\n"
# end

# Iterrate on each expression
each_input do |expr|
    # Parse the expression
    parsed = string2logic(expr)

    # Display the variables
    vars = parsed.getVariables
    vars.each { |var| print "#{var} " }
    print "\n"

    # Display the values
    parsed.each_line do |vars,val|
        vars.each { |var| print "#{var.value ? 1 : 0} " }
        print "#{val ? 1: 0}\n"
    end
    print "\n"
end
