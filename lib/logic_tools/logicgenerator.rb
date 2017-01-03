########################################################
# Tools for automatically generating logic expressions #
########################################################

require "logic_tools/logictree.rb"
require "logic_tools/logiccover.rb"

module LogicTools

    ## Class used for genrating logic expression.
    class Generator

        ## Creates a new generator for logic expressions on the
        #  boolean space based on a +variables+ set.
        def initialize(*variables)
            @variables = variables.map {|var| var.to_s }
            @random = Random.new(0) # The default seed is fixed to 0.
        end

        ## Gets the seed.
        def seed
            @random.seed
        end

        ## Sets the seed to +value+.
        def seed=(value)
            @random = Random.new(value)
        end


        ## Creates a random truth table column value.
        def random_column
            return @random.rand(0..(2**(2**(@variables.size))-1))
        end

        ## Creates a random truth table row value.
        def random_row
            return @random.rand(0..(2**(@variables.size)-1))
        end
        alias random_2row random_row

        ## Creates a random 3-states row.
        def random_3row
            result = "-" * @variables.size
            @variables.size.times do |i| 
                case @random.rand(0..2)
                when 0 then result[i] = "0"
                when 1 then result[i] = "1"
                end
            end
            return result
        end


        ## Creates a minterm from the binary value of a truth table's +row+.
        def make_minterm(row)
            # Convert the +row+ to a bit string if necessary.
            unless (row.is_a?(String))
                row = row.to_s(2).rjust(@variables.size,"0")
            end
            # Create the minterm from the bit string: an AND where
            # each term is variable if the corresponding bit is "1"
            # and the opposite if the corresponding bit is "0".
            return NodeAnd.new(*row.each_char.with_index.map do |bit,j|
                var = NodeVar.new(Variable.get(@variables[j]))
                bit == "1" ? var : NodeNot.new(var)
            end )
        end

        ## Create a standard conjunctive form from its values in a
        #  truth +table+.
        def make_std_conj(table)
            # Convert the +table+ to a bit string if necessary.
            unless table.is_a?(String) then
                table = table.to_s(2).rjust(2 ** @variables.size,"0")
            end
            # Generate the terms from it.
            terms = []
            table.each_char.with_index do |val,i|
                if (val == "1") then
                    terms << make_minterm(i)
                end
            end
            # Generate and return the resulting sum.
            return NodeOr.new(*terms)
        end

        ## Iterates over all the possible standard conjunctive forms.
        #
        #  NOTE: this iteration can be huge!
        def each_std_conj
            # No block given? Return an enumerator.
            return to_enum(:each_bit) unless block_given?
            
            # Block given? Apply it on each bit.
            # Iterate on each possible truth table.
            ( 2 ** (2 ** @variables.size) ).times do |table|
                # Create the expression and apply the block on it.
                yield(make_std_conj(table))
            end
        end

        ## Creates a random minterm.
        def random_minterm
            return make_minterm(random_row)
        end

        ## Creates a random standard conjunctive from.
        def random_std_conj
            return make_std_conj(random_column)
        end



        ## Creates a cube from binary +row+.
        def make_cube(row)
            # Convert the +row+ to a bit string if necessary.
            unless (row.is_a?(String))
                row = row.to_s(2).rjust(@variables.size,"0")
            end
            return Cube.new(row)
        end

        ## Create a 1-cube cover from its values in a truth +table+.
        def make_1cover(table)
            # Convert the +table+ to a bit string if necessary.
            unless table.is_a?(String) then
                table = table.to_s(2).rjust(2 ** @variables.size,"0")
            end
            # Generate the cover.
            cover = Cover.new(*@variables)
            # Fill it with the required 1-cubes.
            table.each_char.with_index do |val,i|
                if (val == "1") then
                    cover << make_cube(i)
                end
            end
            # Returns the cover.
            return cover
        end

        ## Iterates over all the possible cover made of 1-cubes.
        #
        #  NOTE: this iteration can be huge!
        def each_1cover
            # No block given? Return an enumerator.
            return to_enum(:each_bit) unless block_given?
            
            # Block given? Apply it on each bit.
            # Iterate on each possible truth table.
            ( 2 ** (2 ** @variables.size) ).times do |table|
                # Create the expression and apply the block on it.
                yield(make_1cover(table))
            end
        end

        ## Creates a random 1-cube.
        def random_1cube
            return make_cube(random_2row)
        end

        ## Creates a random cover made of 1-cubes.
        def random_1cover
            return make_1cover(random_column)
        end

        ## Creates a random cube.
        def random_cube
            return make_cube(random_3row)
        end

        ## Creates a random cover.
        def random_cover
            # Create the new cover.
            cover = Cover.new(*@variables)
            # Fill it with a random number of random cubes.
            @random.rand(0..(2**(@variables.size))).times do
                cover << make_cube(random_3row)
            end
            # Return it.
            return cover
        end

    end

end
