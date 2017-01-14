
require "logic_tools/logictree.rb"
require "logic_tools/logiccover.rb"
require "logic_tools/minimal_column_covers.rb"
require "logic_tools/logicconvert.rb"

require "logic_tools/traces.rb"

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
                # print "for off cube=#{cube}\n"
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
                # print "blocking row=#{row}\n"
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
    #  NOTE: this step requires to find the minimal column set cover of
    #  a matrix, this algorthim can be very slow and is therefore terminate
    #  before an optimal solution is found is a +deadline+ is exceeded.
    #
    #  Returns the resulting cover.
    def expand(on,off,deadline)
        # Step 1: sort the cubes by weight.
        on = order(on)
        # print "#3.1 #{Time.now}\n"
        # print "on=[#{on.to_s}]\n"

        # Create the resulting cover.
        cover = Cover.new(*on.each_variable)

        # Step 2: Expand the cubes in order of their weights.
        on.each_cube do |cube|
            # print "#3.2 #{Time.now} cube=#{cube}\n"
            # Builds the blocking matrix
            blocking = cube.blocking_matrix(off)
            # print "blocking=[#{blocking}]\n"
            # Select the smallest minimal column cover of the blocking
            # matrix: it will be the expansion
            col_cover = minimal_column_covers(blocking[1..-1],true,deadline)
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


    ## Represents an empty cube.
    #
    #  NOTE: for irredundant usage only.
    class VoidCube < Cube
        def initialize(size)
            # NOTE: This bit string is a phony, since the cube is void.
            super("-" * size)
            # The real bits
            @vbits = " " * size
        end

        ## Evaluates the corresponding function's value for a binary +input+.
        #
        #  +input+ is assumed to be an integer.
        #  Returns the evaluation result as a boolean.
        def eval(input)
            return false
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return @vbits.clone
        end

        ## Iterates over the bits of the cube.
        # 
        #  Returns an enumerator if no block given.
        def each_bit(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_bit) unless block_given?
            
            # Block given? Apply it on each bit.
            @vbits.each_char(&blk)
        end
        alias each each_bit

        ## The bit string defining the cube.
        #
        #  Should not be modified directly, hence set as protected.
        def bits
            raise "A VoidCube cannot be modified."
        end
        protected :bits

        ## Compares with another +cube+.
        def ==(cube) # :nodoc:
            @vbits == cube.bits
        end
        alias eql? ==
        def <=>(cube) #:nodoc:
            @vbits <=> cube.bits
        end

        ## Gets the hash of a cube
        def hash
            @vbits.hash
        end

        ## duplicates the cube.
        def clone # :nodoc:
            VoidCube.new(self.width)
        end
        alias dup clone

        ## Gets the value of bit +i+.
        def [](i)
            @vbits[i]
        end

        ## Sets the value of bit +i+ to +b+.
        def []=(i,b)
            raise "A VoidCube cannot be modified."
        end
    end


    ## Generates the cofactor of +cover+ obtained when +var+ is set to +val+
    #  while keeping the cubes indexes in the cover.
    #
    #  NOTE: for irreduntant only since the resulting cover is not in a
    #  valid state!
    def cofactor_indexed(cover,var,val)
        if val != "0" and val != "1" then
            raise "Invalid value for generating a cofactor: #{val}"
        end
        # Get the index of the variable.
        i = cover.variable_index(var)
        # Create the new cover.
        ncover = Cover.new(*@variables)
        # Set its cubes.
        cover.each_cube do |cube| 
            cube = cube.to_s
            cube[i] = "-" if cube[i] == val
            if cube[i] == "-" then
                ncover << Cube.new(cube)
            else
                # Add an empty cube for keeping the index.
                ncover << VoidCube.new(ncover.width)
            end
        end
        return ncover
    end

    ## Generates the generalized cofactor of +cover+ from +cube+
    #  while keeping the cubes indexes in the cover.
    #
    #  NOTE: for irreduntant only since the resulting cover is not in a
    #  valid state!
    def cofactor_cube_indexed(cover,cube)
        # Create the new cover.
        ncover = Cover.new(*@variables)
        # Set its cubes.
        cover.each_cube do |scube|
            scube = scube.to_s
            scube.size.times do |i|
                if scube[i] == cube[i] then
                    scube[i] = "-" 
                elsif (scube[i] != "-" and cube[i] != "-") then
                    # The cube is to remove from the cover.
                    scube = nil
                    break
                end
            end
            if scube then
                # The cube is to keep in the cofactor.
                ncover << Cube.new(scube)
            else
                # Add an empty cube for keeping the index.
                ncover << VoidCube.new(ncover.width)
            end
        end
        return ncover
    end

    ## Computes the minimal set cover of a +cover+ along with a +dc+ 
    #  (don't care) cover.
    #
    #  Return the set as a list of cube indexes in the cover.
    def minimal_set_covers(cover,dc)
        # print "minimal_set_cover with cover=#{cover} and dc=#{dc}\n"
        # Look for a binate variable to split on.
        binate = (cover+dc).find_binate
        # binate = cover.find_binate
        # # Gets its index
        # i = cover.variable_index(binate)
        unless binate then
            # The cover is actually unate, process it the fast way.
            # Look for "-" only cubes.
            # First in +dc+: if there is an "-" only cube, there cannot
            # be any minimal set cover.
            dc.each_cube do |cube|
                return [] unless cube.each.find { |b| b != "-" }
            end
            # Then in +cover+: each "-" only cube correspond to a cube in the
            # minimal set cover.
            result = []
            cover.each.with_index do |cube,i|
                # print "cube=#{cube} i=#{i}\n"
                result << i unless cube.each.find { |b| b != "-" }
            end
            # print "result=#{result}\n"
            return [ result ]
        else
            # Compute the cofactors over the binate variables.
            cf0 = cofactor_indexed(cover,binate,"0")
            cf1 = cofactor_indexed(cover,binate,"1")
            df0 = cofactor_indexed(dc,binate,"0")
            df1 = cofactor_indexed(dc,binate,"1")
            # Process each cofactor and merge their results
            return [ minimal_set_covers(cf0,df0), minimal_set_covers(cf1,df1) ].flatten(1)
        end
    end


    ## Removes the cubes of the +on+ cover that are redundant for the joint +on+
    #  and +dc+ covers.
    #
    #  NOTE: this step requires to find the minimal column set cover of
    #  a matrix, this algorthim can be very slow and is therefore terminate
    #  before an optimal solution is found is a +deadline+ is exceeded.
    #
    #  Returns the new cover.
    def irredundant(on,dc,deadline)
        # Step 1: get the relatively essential.
        # print "on=#{on}\n"
        cubes, es_rel = on.each_cube.partition do |cube| 
            ((on+dc) - cube).cofactor_cube(cube).is_tautology?
        end
        return on.clone if cubes.empty? # There were only relatively essentials.
        # print "cubes = #{cubes}\n"
        # print "es_rel = #{es_rel}\n"
        
        # Step 2: get the partially and totally redundants.
        es_rel_dc = Cover.new(*on.each_variable)
        es_rel.each { |cube| es_rel_dc << cube }
        dc.each { |cube| es_rel_dc << cube }
        red_tot, red_par = cubes.partition do |cube|
            es_rel_dc.cofactor_cube(cube).is_tautology?
        end
        # red_par is to be used as a cover.
        red_par_cover = Cover.new(*on.each_variable)
        red_par.each { |cube| red_par_cover << cube }
        # print "es_rel_dc = #{es_rel_dc}\n"
        # print "red_tot = #{red_tot}\n"
        # print "red_par = #{red_par}\n"

        # Step 3: get the minimal sets of partially redundant.
        red_par_sets = red_par.map do |cube|
            # print "for cube=#{cube}\n"
            minimal_set_covers( cofactor_cube_indexed(red_par_cover,cube),
                               cofactor_cube_indexed(es_rel_dc,cube) )
        end
        # red_par_sets.each { |set| set.map! {|i| red_par[i] } }
        # print "red_par_sets=#{red_par_sets}\n"

        # Step 4: find the smallest minimal set using the minimal column covers
        # algorithm.
        # For that purpose build the boolean matrix whose columns are for the
        # partially redundant cubes and the rows are for the sets, "1" 
        # indication the cube is the in set.
        matrix = [] 
        red_par_sets.each do |sets|
            sets.each do |set|
                row = "0" * red_par.size
                set.each { |i| row[i] = "1" }
                matrix << row
            end
        end
        # print "matrix=#{matrix}\n"
        smallest_set_cols = minimal_column_covers(matrix,true,deadline)
        # print "smallest_set_cols=#{smallest_set_cols}\n"
        
        # Creates a new cover with the relative essential cubes and the
        # smallest set of partially redundant cubes.
        cover = Cover.new(*on.each_variable)
        es_rel.each { |cube| cover << cube.clone }
        # smallest_set_cols.each do |set| 
        #     set.each { |col| cover << red_par[col].clone }
        # end
        smallest_set_cols.each { |col| cover << red_par[col].clone }
        # print "cover=#{cover}\n"
        return cover 
    end

    ## Remove quickly some cubes of the +on+ cover that are redundant.
    #
    #  Returns the new cover.
    def irredundant_partial(on)
        result = Cover.new(*on.each_variable)
        on.each.with_index do |cube,i|
            # Is cube included somewhere?
            unless on.each.with_index.find {|cube1,j| j != i and cube1.include?(cube) }
                # No, keep the cube.
                result << cube
            end
        end
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
        # print "max_reduce with cube=#{cube} on=#{on} dc=#{dc}\n"
        # Step 1: create the cover to get the reduction from.
        cover = ((on + dc) - cube).cofactor_cube(cube)
        # print "cover=#{cover}, taut=#{cover.is_tautology?}\n"
        # Step 2: complement it
        compl = cover.complement
        # print "compl=#{compl}\n"
        # Step 3: get the smallest cube containing the complemented cover
        sccc = compl.smallest_containing_cube
        # print "sccc=#{sccc}\n"
        # The result is the intersection of this cube with +cube+.
        return cube.intersect(sccc)
    end

    ## Reduces cover +on+ esuring +dc+ (don't care) is not intersected.
    #
    #  Returns the resulting cover.
    def reduce(on,dc)
        # Step 1: sorts on's cubes to achieve a better reduce.
        on = order(on)
        # print "ordered on=#{on.to_s}\n"
        
        # Step 2: reduce each cube and add it to the resulting cover.
        cover = Cover.new(*on.each_variable)
        on.each_cube.to_a.reverse_each do |cube|
            reduced = max_reduce(cube,on,dc)
            # print "cube=#{cube} reduced to #{reduced}\n"
            cover << reduced if reduced # Add the cube if not empty
            on = (on - cube)
            on << reduced if reduced # Add the cube if not empty
        end
        return cover
    end


    # Enhances the Cover class with simplifying using the Espresso
    # algorithm.
    class Cover

        include LogicTools::Traces

        # ## The deadline for minimal columns covers.
        # @@deadline = Float::INFINITY
        # def Cover.deadline
        #     @@deadline
        # end


        ## Generates an equivalent but simplified cover from a set
        #  splitting it for faster solution.
        #
        #  Param: 
        #  * +deadline+:: the deadline for each step in second.
        #  * +volume+::   the "volume" above which the cover is split before
        #                 being solved.
        #
        #  NOTE: the deadline is acutally applied to the longest step
        #  only.
        #
        def split_simplify(deadline,volume)
            # The on set is a copy of self [F].
            on = self.simpler_clone
            on0 = Cover.new(*@variables)
            (0..(on.size/2-1)).each do |i|
                on0 << on[i].clone
            end
            on1 = Cover.new(*@variables)
            (((on.size)/2)..(on.size-1)).each do |i|
                on1 << on[i].clone
            end
            debug { "on0=#{on0}\n" }
            debug { "on1=#{on1}\n" }
            # Simplify each part independently
            on0 = on0.simplify(deadline,volume)
            on1 = on1.simplify(deadline,volume)
            # And merge the results for simplifying it globally.
            on = on0 + on1
            on.uniq!
            new_cost = cost(on)
            if (new_cost >= @first_cost) then
                info { "Giving up with final cost=#{new_cost}" }
                # Probably not much possible optimization, end here.
                result = self.clone
                result.uniq!
                return result
            end
            # Try to go on but with a timer (set to 7 times the deadline since
            # there are 7 different steps in total).
            begin
                Timeout::timeout(7*deadline) {
                    on = on.simplify(deadline,Float::INFINITY)
                }
            rescue Timeout::Error
                info do
                    "Time out for global optimization, ends here..."
                end
            end
            info do
                "Final cost: #{cost(on)} (with #{on.size} cubes)"
            end
            return on
        end




        ## Generates an equivalent but simplified cover.
        #
        #  Param:
        #  * +deadline+:: the deadline for irredudant in seconds.
        #  * +volume+::   the "volume" above which the cover is split before
        #                 being solved.
        #
        #  Uses the Espresso method.
        def simplify(deadline = Float::INFINITY, volume = Float::INFINITY)
            # Compute the cost before any simplifying.
            @first_cost = cost(self)
            info do
                "Cost before simplifying: #{@first_cost} " +
                "(with #{@cubes.size} cubes)"
            end
            # If the cover is too big, split before solving.
            if (self.size > 2) and (self.size * (self.width ** 2) > volume) then
                return split_simplify(deadline,volume)
            end

            # Step 1:
            # The on set is a copy of self [F].
            on = self.simpler_clone

            # Initialization
            #
            # print "on=#{on}\n"
            # print "#1 #{Time.now}\n"
            # And the initial set of don't care: dc [D].
            dc = Cover.new(*on.each_variable) # At first dc is empty

            # print "#2 #{Time.now}\n"
            # Step 2: generate the complement cover: off [R = COMPLEMENT(F)].
            off = on.complement
            # off = irredundant_partial(off) # quickly simlify off.
            # print "off=#{off}\n"
            info { "off with #{off.size} cubes." }

            #
            # Process the cover by pieces if the off and the on are too big.
 
            # If on and off are too big together, split before solving.
            if (on.size > 2) and (on.size*off.size > volume) then
                return split_simplify(deadline,volume)
            end

            # print "#3 #{Time.now}\n"
            # Step 3: perform the initial expansion [F = EXPAND(F,R)].
            on = expand(on,off,deadline)
            # print "expand:\non=#{on}\n"
            # Remove the duplicates.
            on.uniq!

            # print "#4 #{Time.now}\n"
            # Step 4: perform the irredundant cover [F = IRREDUNDANT(F,D)].
            on = irredundant(on,dc,deadline)
            # print "irredundant:\non=#{on}\n"

            # print "#5 #{Time.now}\n"
            # Step 5: Detect the essential primes [E = ESSENTIAL(F,D)].
            essentials = essentials(on,dc)
            # print "essentials=#{essentials}\n"

            # print "#6 #{Time.now}\n"
            # Step 6: remove the essential primes from on and add them to dc
            on = on - essentials
            dc = dc + essentials

            # Optimiation loop
            
            # Computes the cost after preprocessing.
            new_cost = cost(on)
            essentials_cost = cost(essentials)
            info { "After preprocessing, cost=#{new_cost+essentials_cost}" }
            if new_cost >0 then
                begin
                    # print "#7.1 #{Time.now}\n"
                    cost = new_cost
                    # Step 1: perform the reduction of on [F = REDUCE(F,D)]
                    on = LogicTools.reduce(on,dc)
                    # print "reduce:\non=#{on.to_s}\n"
                    # Step 2: perform the expansion of on [F = EXPAND(F,R)]
                    on = expand(on,off)
                    # Also remove the duplicates
                    on.uniq!
                    # Step 3: perform the irredundant cover [F = IRREDUNDANT(F,D)]
                    on = irredundant(on,dc)
                    # on.each_cube do |cube|
                    #     if ((on+dc)-cube).cofactor_cube(cube).is_tautology? then
                    #         print "on=[#{on}]\ndc=[#{dc}]\ncube=#{cube}\n"
                    #         raise "REDUNDANT AFTER IRREDUNDANT"
                    #     end
                    # end
                    # Step 4: compute the cost
                    new_cost = cost(on)
                    info { "cost=#{new_cost+essentials_cost}" }
                end while(new_cost < cost)
            end

            # Readd the essential primes to the on result
            on += essentials

            # This is the resulting cover.
            info { "Final cost: #{cost(on)} (with #{on.size} cubes)" }
            return on
        end
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

            # Step 1: generate the simplified cover.
            cover = self.to_cover.simplify

            # Step 2: generate the resulting tree from the resulting cover.
            return cover.to_tree
        end
    end
end
