########################################################################
# Logic cover classes: used for describing covers of boolean functions #
########################################################################


require "logic_tools/minimal_column_covers.rb"

module LogicTools

    ## 
    #  Represents a boolean cube.
    class Cube
        
        ## Creates a new cube from a bit string +bits+.
        def initialize(bits)
            @bits = bits.to_s
            unless @bits.match(/^[01-]*$/)
                raise "Invalid bit string for describing a cube: "+ @bits
            end
        end

        ## Gets the widths (number of variables of the boolean space).
        def width
            return @bits.length
        end

        ## Converts to a string.
        def to_s # :nodoc:
            @bits.clone
        end

        ## Iterates over the bits of the cube.
        # 
        #  Returns an enumerator if no block given.
        def each(&blk)
            # No block given? Returns an enumerator
            return to_enum(:each) unless block_given?
            
            # Block given? Applies it on each bit.
            @bits.each_char(&blk)
        end

        ## The bit string defining the cube.
        #
        #  Should not be modified directly, hence set as protected.
        attr_reader :bits
        protected :bits

        ## Compares with another +cube+.
        def ==(cube) # :nodoc:
            @bits == cube.bits
        end
        def <=>(cube) #:nodoc:
            @bits <=> cube.bits
        end

        ## duplicates the cube.
        def clone # :nodoc:
            Cube.new(self)
        end
        alias dup clone

        ## Gets the value of bit +i+.
        def [](i)
            @bits[i]
        end

        ## Sets the value of bit +i+ to +b+.
        def []=(i,b)
            raise "Invalid bit value: #{b}" unless ["0","1","-"].include?(b)
            # Update the bit string
            @bits[i] = b 
        end
    end


    ##
    # Represents a cover of a boolean function.
    class Cover

        ## Creates a new cover on a boolean space represented by a list of 
        #  +variables+.
        def initialize(*variables)
            @variables = variables
            # Initialize the cover
            @cubes = []
            # @sorted = false # Initialy, the cover is not sorted
        end

        ## Gets the width (the number of variables of the boolean space).
        def width
            return @variables.length
        end

        ## Adds a +cube+ to the cover.
        #
        #  Creates a new cube if +cube+ is not an instance of LogicTools::Cube.
        def add(cube)
            # Check the cube.
            cube = Cube.new(cube) unless cube.is_a?(Cube)
            if cube.width != self.width then
                raise "Invalid cube: #{cube}(#{cube.class})"
            end
            # The cube is valid, add it.
            @cubes.push(cube)
            # # The cubes of the cover are therefore unsorted.
            # @sorted = false
        end
        alias << add

        ## Iterates over the cubes of the cover.
        #
        #  Returns an enumerator if no block is given.
        def each_cube(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_cube) unless block_given?
            # Block given? Apply it.
            @cubes.each(&blk)
        end
        alias cube each_cube

        ## Iterates over the variables of the cube
        #
        #  Returns an enumberator if no block is given
        def each_variable(&blk)
            # No block given? Return an enumerator
            return to_enum(:each_variable) unless block_given?
            # Block given? Apply it.
            @variables.each(&blk)
        end

        # ## Sorts the cubes.
        # def sort!
        #     @cubes.sort! unless @sorted
        #     # Remember the cubes are sorted to avoid doing it again.
        #     @sorted = true
        #     return self
        # end

        ## Removes duplicate cubes.
        def uniq!
            @cubes.uniq!
            return self
        end

        ## Looks for a binate variable.
        #  
        #  Returns the found binate variable or nil if not found.
        #
        #  NOTE: Can also be used for checking if the cover is unate.
        def is_unate?
            # Merge the cube over one another until a 1 over 0 or 0 over 1
            # is met.
            # The merging rules are to followings:
            # 1 over 1 => 1
            # 1 over - => 1
            # 1 over 0 => not unate
            # 0 over 0 => 0
            # 0 over - => 0
            # 0 over 1 => not unate
            merge = "-" * self.width
            self.each_cube do |cube|
                cube.each.with_index do |bit,i|
                    if bit == "1" then
                        if merge[i] == "0" then
                            # A 1 over 0 is found, a binate variable is found.
                            return @variables[i]
                        else
                            merge[i] = "1"
                        end
                    elsif bit == "0" then
                        if merge[i] == "1" then
                            # A 0 over 1 is found, a binate variable is found.
                            return @variables[i]
                        else
                            merge[i] = "0"
                        end
                    end
                end
            end
            # The cover is unate: no binate variable.
            return nil
        end

        
        ## Creates the union of self and +cover+.
        def unite(cover)
            # Check if the covers are compatible.
            if (cover.each_variables.to_a != @variables) then
                raise "Cover #{cover} cannot be united to."
            end
            # Creates the union cover.
            union = Cover.new(*@variables)
            # Fill it with the cubes of each cover.
            self.each_cube {|cube| union.add(cube) }
            cover.each_cube {|cube| union.add(cube) }
            # Return the result.
        end


        ## Generates the complement cover.
        def complement
            # Look for a binate variable to split on.
            binate = self.binate
            # Gets its index
            i = @variables.index_of(binate)
            unless binate then
                # The cover is actually unate, complement it the fast way.
                # Step 1: Generate the following boolean matrix:
                # each "0" and "1" is transformed to "1"
                # each "-" is transformed to "0"
                matrix = []
                self.each_cube do |cube|
                    line = " " * self.width
                    mask << line
                    cube.each.with_index do |bit,i|
                        line[i] bit == "0" or bit == "1" ? "1" : "0"
                    end
                end
                # Step 2: finds all the minimal column covers of the matrix
                mins = minimal_column_covers(matrix)
                # Step 3: generates the complent cover from the minimal
                # column covers.
                # Each minimal column cover is converted to a cube using
                # the following rules (only valid because the initial cover
                # is unate):
                # * a minimal column whose variable can be reduced to 1
                #   is converted to the not of the variable
                # * a minimal column whose variable can be reduced to 0 is
                #   converted to the variable
                #
                # +result+ is the final complement cover.
                result = Cover.new(@variables)
                mins.each do |min|
                    # +cbits+ is the bit string describing the cube built
                    # from the column cover +min+.
                    cbits = "-" * self.width
                    min.each do |col|
                        if self.each_cube.find {|cube| cube[col] == "1" } then
                            cbits[col] = "0"
                        else
                            cbits[col] = "1"
                        end
                    end
                    result << new Cube(cbits)      
                end
                return result
            else
                # Compute the cofactors over the binate variables.
                cf0 = self.cofactor(binate,0)
                cf1 = self.cofactor(binate,1)
                # Complement them.
                cf0 = cf0.complement
                cf1 = cf1.complement
                # Build the resulting complement cover as:
                # (cf0 and (not binate)) or (cf1 and binate)
                cf0.each_cube {|cube| cube[i] = "0" } # cf0 and (not binate)
                cf1.each_cube {|cube| cube[i] = "1" } # cf1 and binate
                return cf0.unite(cf1)
            end
        end
    end

end
