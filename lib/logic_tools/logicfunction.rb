##############################################################
# Logic function class: used for describing a logic function #
##############################################################


require "logic_tools/logictree.rb"


module LogicTools


    ## 
    # Represents a logic function.
    #
    # A logic function is described as a set of logic trees (LogicTools::Node)
    # associated to variables (LogicTools::Variable) repreenting each one
    # one-bit output. The inputs are represented by the variables contained
    # by the variable nodes (LogicTools::NodeVar) of the trees.
    #
    # Functions can be composed together through their variables.
    class Function
        
        ## Creates a new empty function.
        def initialize
            @assigns = {}
        end
        
        ## duplicates the function.
        def clone # :nodoc:
            result = Function.new
            @assigns.each { |output,tree| result.add(output,tree.clone) }
            return result
        end
        alias dup clone

        ## Adds an +output+ variable associated with a +tree+ for computing it.
        def add(output,tree)
            unless tree.is_a?(Node)
                raise "Invalid class for a logic tree: #{tree.class}"
            end
            @assigns[Variable.get(output)] = tree
        end
        alias []= add

        ## Gets the tree corresponding to an +output+ variable.
        def get(output)
            return @assigns[Variable.get(variable)]
        end
        alias [] get

        ## Iterates over the assignments of the functions.
        def each(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each) unless block_given?

            # Block given? Apply it.
            @assigns.each(&blk)
        end

        ## Iterates over the output variables of the function.
        def each_output(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_output) unless block_given?

            # Block given? Apply it.
            @assigns.each_key(&blk)
        end

        ## Gets a array containing the variables of the function sorted by name.
        def get_variables
            result = @assigns.each_value.reduce([]) do |ar,tree|
                ar.concat(tree.get_variables)
            end
            result.uniq!.sort!
            return result
        end

        ## Iterates over the trees of the function.
        def each_tree(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_tree) unless block_given?

            # Block given? Apply it.
            @assigns.each_value(&blk)
        end

        ## Convert to a string.
        def to_s # :nodoc:
            result = @assigns.each.reduce("[") do |str,assign|
                str << assign[0].to_s
                str << "="
                str << assign[1].to_s
                str << ","
            end
            result[-1] = "]"
            return result
        end

    end

end
