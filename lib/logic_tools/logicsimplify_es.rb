###################################################################
# Logic tree classes extension for simplifying a logic expression #
# using the Espresso method                                       #
###################################################################


require "logic_tools/logictree.rb"
require "logic_tools/logiccover.rb"
require "logic_tools/minimal_column_covers.rb"
require "logic_tools/logicconvert.rb"

module LogicTools


    # Enhances the Cube class with methods for applying the
    # Espresso algorithm
    class Cube

        ## Computes the blocking matrix relatively to an +off+ cover.
        #
        #  NOTE: * The blocking matrix's first row gives the column number
        #          of each litteral of the cube.
        #        * The blocking matrix's other rows represents the cubes
        #          of the off cover.
        #        * The block matrix's cells are set to "1" if corresponding
        #          +self+ litteral has a different polarity (1,0 or 0,1) than
        #          the corresponding off cover's cube and set to "0" otherwise
        #          (including the "-" cases).
        def blocking_matrix(off)
            # Create the result matrix.
            blocking = []
            # Get the column number of the litterals of self.
            litterals = @bits.size.times.find_all {|i| @bits[i] != "-" } 
            # This is the first row of the blocking matrix.
            blocking << litterals
            # Build the other rows: one per cube of the off cover.
            off.each_cube do |cube|
                # Create the new row: by default blocking.
                row = "0" * litterals.size
                blocking << row
                # Fill it
                litterals.each.with_index do |col,i|
                    if cube[col] != "-" and @bits[col] != cube[col] then
                        # Non blocking, put a "1".
                        row[i] = "1"
                    end
                end
            end
            # Returns the resulting matrix
            return blocking
        end
    end


    ## Sorts the cubes of a +cover+ by weight.
    #
    #  Returns a new cover containing the sorted cubes.
    def order(cover)
        # Step 1: Compute the weight of each cube
        weights = [ 0 ] * cover.size
        # For that purpose first compute the weight of each column
        # (number of ones)
        col_weights = [ 0 ] * cover.width
        cover.width.times do |i|
            cover.each_cube { |cube| col_weights[i] += 1 if cube[i] == "1" }
        end
        # Then the weight of a cube is the scalar product of its
        # bits with the column weights.
        cover.each_cube.with_index do |cube,j|
            cube.each.with_index do |bit,i|
                weights[j] += col_weights[i] if bit == "1"
            end
        end

        # Step 2: stort the cubes by weight
        new_cubes = cover.each_cube.sort_by.with_index { |cube,i| weights[i] }
        
        # Creates a new cover with the sorted cubes and return it.
        sorted = Cover.new(*cover.each_variable)
        new_cubes.each { |cube| sorted << cube }
        return sorted
    end


    ## Expands cover +on+ as long it does not intersects with +off+.
    #
    #  Returns the resulting cover.
    def expand(on,off)
        # Step 1: sort the cubes by weight.
        on = order(on)
        # print "#3.1 #{Time.now}\n"

        # Create the resulting cover.
        cover = Cover.new(*on.each_variable)

        # Step 2: Expand the cubes in order of their weights.
        on.each_cube do |cube|
            # print "#3.2 #{Time.now} cube=#{cube}\n"
            # Builds the blocking matrix
            blocking = cube.blocking_matrix(off)
            # Select the smallest minimal column cover of the blocking
            # matrix: it will be the expansion
            col_cover = minimal_column_covers(blocking[1..-1],true)
            # print "col_cover=#{col_cover}\n"
            # This is the new cube
            bits = "-" * cube.width
            col_cover.each do |col|
                # The first row of the blocking matrix give the actual
                # column of the litteral
                col = blocking[0][col] 
                bits[col] = cube[col]
            end
            # print "expand result=#{bits}\n"
            # Create and add the new expanded cube.
            cover << Cube.new(bits)
        end

        return cover
    end

    ## Computes the minimal set cover of a +cover+ along with a +dc+ 
    #  (don't care) cover.
    #
    #  Return the set as a list of cube indexes in the cover.
    def minimal_set_cover(cover,dc)
        # Look for a binate variable to split on.
        binate = (cover+dc).find_binate
        # Gets its index
        i = @variables.index(binate)
        unless binate then
            # The cover is actually unate, process it the fast way.
            # Look for "-" only cubes.
            # First in +dc+: if there is an "-" only cube, there cannot
            # be any minimal set cover.
            dc.each_cube do |cube|
                return [] unless cube.each.find { |b| b != "-" }
            end
            # The in +cover+: each "-" only correspond to a cube in the
            # minimal set cover.
            result = []
            cover.each.with_index do |cube,i|
                result << i unless cube.each.find { |b| b != "-" }
            end
        else
            # Compute the cofactors over the binate variables.
            cf0 = cover.cofactor(binate,"0")
            cf1 = cover.cofactor(binate,"1")
            df0 = dc.cofactor(binate,"0")
            df1 = dc.cofactor(binate,"1")
            # Process each cofactor and merge their results
            return minimal_set_cover(cf0,df0) + minimal_set_cover(cf1,df1)
        end
    end


    ## Remove the cubes of the +on+ cover that are redundant for the joint +on+
    #  and +dc+ covers.
    #
    #  Returns the new cover.
    def irredundant(on,dc)
        # Step 1: get the relatively essential.
        cubes, es_rel = on.each_cube.partition do |cube| 
            (on - cube).cofactor_cube(cube).is_tautology?
        end
        return on.clone if cubes.empty? # There were only relatively essentials.
        
        # Step 2: get the partially and totally redundants.
        es_rel_dc = Cover.new(*on.each_variable)
        es_rel.each { |cube| es_rel_dc << cube }
        dc.each { |cube| es_rel_dc << cube }
        red_tot, red_par = cubes.partition do |cube|
            es_rel_dc.cofactor_cube(cube).is_tautology?
        end

        # Step 3: get the minimal sets of partially redundant.
        red_par_sets = red_par.map do |cube|
            minimal_set_covers(red_par.cofactor_cube(cube),
                               es_rel_dc.cofactor_cube(cube))
        end

        # Step 4: find the smallest minimal set using the minimal column covers
        # algorithm.
        # For that purpose build the boolean matrix whose columns are for the
        # partially redundant cubes and the rows are for the sets, "1" 
        # indication the cube is the in set.
        matrix = red_par_sets.map do |set|
            row = "0" * red_par.size
            red_par.each.with_idex do |cube,i| 
                row[i] = "1" if set.include?(cube)
            end
        end
        smallest_set_cols = minimal_column_covers(matrix,true)
        
        # Creates a new cover with the relative essential cubes and the
        # smallest set of partially redundant cubes.
        cover = Cover.new(*on.each_variable)
        es_rel.each { |cube| cover << cube.clone }
        smallest_set_cols.each do |set| 
            set.each { |col| cover << red_par[col].clone }
        end
        return cover 
    end


    ## Get the essential cubes from the +on+ cover which are not covered
    #  by the +dc+ (don't care) cover.
    #
    #  Returns the new cover.
    def essentials(on,dc)
        # Create the essential list.
        es = []

        # For each cube of on, check if it is essential.
        on.each_cube do |cube|
            # Step 1: build the +cover+ (on-cube)+dc.
            # NOTE: could be done without allocating multiple covers,
            # but this is much readable this way, so kept as is as long
            # as there do not seem to be any much performance penalty.
            cover = (on-cube)+dc
            # Step 2: Gather the concensus beteen each cube of +cover+
            # and their sharp with +cube+.
            cons = Cover.new(*on.each_variable)
            cover.each_cube do |ccube|
                # Depending on the distance.
                dist = cube.distance(ccube)
                # If the distance is >1 there is no consensus.
                # Otherwise:
                if (dist == 1) then
                    # The distance is 1, the consensus is computed directly.
                    cons << ccube.consensus(cube)
                elsif (dist == 0)
                    # The distance is 0, sharp ccube from cube and
                    # compute the concensus from each resulting prime cube.
                    ccube.sharp(cube).each do |scube|
                        scube = scube.consensus(cube)
                        cons << scube if scube
                    end
                end
            end
            # Step 3: check if +cube+ is covered by cover+cons.
            # This is done by checking is the cofactor with cube
            # is not a tautology.
            unless (cons+dc).cofactor_cube(cube).is_tautology?
                # +cube+ is not covered by cover+cons, it is an essential.
                es << cube
            end
        end
        
        # Create the resulting cover.
        result = Cover.new(*on.each_variable)
        es.each { |es| result << es }
        return result
    end


    ## Computes the cost of a +cover+.
    #
    #  The cost of the cover is sum of the number of variable of each cube.
    def cost(cover)
        return cover.each_cube.reduce(0) do |sum, cube|
            sum + cube.each_bit.count { |b| b != "-" }
        end
    end

    ## Compute the maximum reduction of a cube from an +on+ cover
    #  which does not intersect with another +dc+ cover.
    def max_reduce(cube,on,dc)
        # Step 1: create the cover to get the reduction from.
        cover = ((on + dc) - cube).cofactor_cube(cube)
        # Step 2: complement it
        cover = cover.complement
        # Step 3: get the smallest cube containing the complemented cover
        sccc = cover.smallest_containing_cube
        # The result is the intersection of this cube with +cube+.
        return cube.intersect(sccc)
    end

    ## Reduces cover +on+ esuring +dc+ (don't care) is not intersected.
    #
    #  Returns the resulting cover.
    def reduce(on,dc)
        # Step 1: sorts on's cubes to achieve a better reduce.
        on = order(on)
        
        # Step 2: reduce each cube and add it to the resulting cover.
        cover = Cover.new(*on.each_variable)
        on.each_cube.to_a.reverse_each do |cube|
            reduced = max_reduce(cube,on,dc)
            cover << reduced
            on = (on - cube)
            on << reduced
        end
        return cover
    end


    # Enhances the Node class with expression simplifying using the
    # Espresso algorithm.
    class Node

        ## Generates an equivalent but simplified representation of the
        #  expression represented by the tree rooted by the current node.
        #
        #  Uses the Espresso method.
        def simplify()
            # Initialization

            # print "#0 #{Time.now}\n"
            # Step 1: generate the initial cover: on [F].
            on = self.to_cover
            # print "on=#{on}\n"
            # print "#1 #{Time.now}\n"
            # And the initial set of don't care: dc [D].
            dc = Cover.new(*on.each_variable) # At first dc is empty

            # print "#2 #{Time.now}\n"
            # Step 2: generate the complement cover: off [R = COMPLEMENT(F)].
            off = on.complement
            # print "off=#{off}\n"

            # print "#3 #{Time.now}\n"
            # Step 3: perform the initial expansion [F = EXPAND(F,R)].
            on = expand(on,off)
            # print "on=#{on}\n"

            # print "#4 #{Time.now}\n"
            # Step 4: perform the irredundant cover [F = IRREDUNDANT(F,D)].
            on = irredundant(on,dc)
            # Also remove the duplicates
            on.uniq!
            # print "on=#{on}\n"

            # print "#5 #{Time.now}\n"
            # Step 5: Detect the essential primes [E = ESSENTIAL(F,D)].
            essentials = essentials(on,dc)
            # print "essentials=#{essentials}\n"

            # print "#6 #{Time.now}\n"
            # Step 6: remove the essential primes from on and add them to dc
            on = on - essentials
            dc = dc + essentials

            # Optimiation loop
            
            # Computes the initial cost
            new_cost = cost(on)
            # print "After prerpocessing, cost=#{new_cost}\n"
            begin
                cost = new_cost
                # Step 1: perform the reduction of on [F = REDUCE(F,D)]
                on = LogicTools.reduce(on,dc)
                # Step 2: perform the expansion of on [F = EXPAND(F,R)]
                on = expand(on,off)
                # Step 3: perform the irredundant cover [F = IRREDUNDANT(F,D)]
                on = irredundant(on,dc)
                # Also remove the duplicates
                on.uniq!
                # Step 4: compute the cost
                new_cost = cost(on)
                # print "cost=#{new_cost}\n"
            end while(new_cost < cost)

            # Readd the essential primes to the on result
            on += essentials

            # Generate the resulting tree from the resulting on set
            return on.to_tree
        end
    end
end
