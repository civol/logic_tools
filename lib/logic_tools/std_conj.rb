#!/usr/bin/env ruby
##############################################################
# Convert a logic expression to its conjunctive normal form  #
##############################################################


# For building logic tress
require "#{Dir.getwd}/logictree.rb"

# For parsing the inputs
require "#{Dir.getwd}/logicparse.rb"

include LogicTools





############################
# The main program

# First gets the expression to treat
$expr = nil
# Is it in the arguments?
unless $*.empty? then
    # Yes, get the expression from them
    $expr = $*.join
else
    # Get the expression from standard input
    print "Please enter your expression and end with ^D:\n"
    $expr = ARGF.read
end

# Parse the expression
$parsed = string2logic($expr)

# Generates its conjunctive normal form
$conj = $parsed.to_std_conjunctive

# print "Computation done\n"

# Display the result
print $conj.to_s, "\n"
