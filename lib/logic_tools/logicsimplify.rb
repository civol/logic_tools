###################################################################
# Logic tree classes extension for simplifying a logic expression #
# using the Quine-Mc Cluskey method                               #
###################################################################


require 'set'


module LogicTools


    ## Converts an array of variable to bit vector according to their value
    #  @param vars the array of variables to convert
    def vars2int(vars)
        res = ""
        vars.each_with_index do |var,i|
            res[i] = var.value ? "1" : "0"
        end
        res
    end





    # Class describing an implicant
    class Implicant
        include Enumerable
        attr_reader :mask,   # The positions of the x 
                    :bits,   # The bit vector of the implicant
                    :count,  # The number of 1 of the implicant
                    :covers, # The bit values covered by the implicant
                    :prime   # Tell if the implicant is prime or not
        attr_accessor :var   # The variable associated with the implicant
                             # Do not interfer at all with the class, so
                             # public and fully accessible
        protected
        attr_writer :covers
        public

        ## Create an implicant
        #  @param base if Implicant: copy constructor <br>
        #              otherwise: creat a new implicant from a bit string
        def initialize(base)
            if base.is_a?(Implicant)
                @covers = base.covers.dup
                @bits = base.bits.dup
                @mask = base.mask.dup
                @count = base.count
            else
                @bits = base.to_s
                unless @bits.match(/^[01]*$/)
                    raise "Invalid bit string for an initial implicant: " + @bits
                end
                @mask = " " * @bits.size
                @count = @bits.count("1")
                @covers = [ @bits ]
            end
            @prime = true # By default assumed prime
        end

        ## Convert to a string
        def to_s
            @bits
        end

        ## inspect
        def inspect
            @bits.dup
        end

        ## Set the prime status
        #  @param st the new status (true or false)
        def prime=(st)
            @prime = st ? true : false
        end

        ## Iterate overs the bits of the implicant
        def each(&blk)
            @bits.each_char(&blk)
        end

        # Compare implicants
        # @param imp the implicant (or simply bit string) to compare with
        def ==(imp)
            @bits == imp.to_s
        end
        def <=>(imp)
            @bits <=> imp.to_s
        end

        # duplicates the implicant
        def dup
            Implicant.new(self)
        end

        ## Get a bit by index
        #  @param i the index in the bit string of the implicant
        def [](i)
            @bits[i]
        end

        ## Set a bit by index
        #  @param i the index in the bit string of the implicant
        #  @param b the bit to set
        def []=(i,b)
            raise "Invalid bit value: #{b}" unless ["0","1","x"].include?(b)
            return if @bits[i] == b # Already set
            # Update count and mask
            @count -= 1 if @bits[i] == "1"    # One 1 less
            @count += 1 if b == "1"           # One 1 more
            @mask[i] = " " if @bits[i] == "x" # One x less
            @mask[i] = "x" if b == "x"        # One x more
            # Update the bit string
            @bits[i] = b 
        end


        ## Merge with another implicant
        #  @param imp the implicant to merge with
        #  @return the resulting implicant
        def merge(imp)
            # Has imp the same mask?
            return nil unless imp.mask == @mask
            # First look for a 1-0 or 0-1 difference
            found = nil
            @bits.each_char.with_index do |b0,i|
                b1 = imp.bits[i]
                # Bits are different
                if (b0 != b1) then
                    # Stop if there where already a difference
                    if (found)
                        found = nil
                        break
                    end
                    # A 0-1 or a 1-0 difference is found
                    found = i
                end
            end
            # Can merge at bit found
            if found then
                # print "merge!\n"
                # Duplicate current implicant
                merged = self.dup
                # And update its x
                merged[found] = "x"
                # Finally update its covers
                merged.covers = @covers | imp.covers
                return merged
            end
            # No merge
            return nil
        end
    end

    # Class describing a group of implicants with only singletons, sortable
    # by number of ones
    class SameXImplicants
        include Enumerable

        ## Default constructor
        def initialize
            @implicants = []
            @singletons =  Set.new # Set used for ensuring each implicant is
                                   # present only once in the group
        end

        ## Ge the size of the group
        def size
            @implicants.size
        end

        ## Iterate of the implicants
        def each(&blk)
            @implicants.each(&blk)
        end

        ## Access by index
        #  @param i the index
        def [](i)
            @implicants[i]
        end

        ## Add an implicant
        #  @param imp the implicant to add
        def add(imp)
            return if @singletons.include?(imp.bits) # Implicant already present
            @implicants << imp
            @singletons.add(imp.bits.dup)
        end
        alias :<< :add

        # Sort the implicants by number of ones
        def sort!
            @implicants.sort_by! {|imp| imp.count }
        end

        # Convert to a string
        def to_s
            @implicants.to_s
        end
        def inspect
            to_s
        end
    end

    ## Class describing a pseudo variable associated to an implicant
    #  Used for the Petrick's method
    class VarImp < Variable
        @@base = 0 # The index of the VarImp for building the variable names

        attr_reader :implicant

        ## Create the variable
        #  @param imp the implicant to create the variable from
        def initialize(imp)
            # Create the name of the variable
            name = nil
            begin
                name = "P" + @@base.to_s
                @@base += 1
            end while Variable.exists?(name)
            # Create the variable
            super(name)
            # Associate it with the implicant
            @implicant = imp
            imp.var = self
        end
    end



    # Enhance the Node class with expression simplifying
    class Node
        
        ## Generates an equivalent but simplified representation of the
        #  function.<br>
        #  Uses the Quine-Mc Cluskey method
        def simplify
            # Step 1: get the generators
            
            # Gather the minterms which set the function to 1 encoded as
            # bitstrings
            minterms = []
            each_minterm do |vars|
                minterms << vars2int(vars)
            end

            # print "minterms = #{minterms}\n"

            # Create the implicant table
            implicants = Hash.new {|h,k| h[k] = SameXImplicants.new }

            # Convert the minterms to implicants without x
            minterms.each do |term|
                imp = Implicant.new(term)
                implicants[imp.mask] << imp
            end

            # print "implicants = #{implicants}\n"

            # Group the adjacent implicants to obtain the generators
            size = 0
            generators = []
            # The main iterator
            has_merged = nil
            begin
                has_merged = false
                mergeds = Hash.new { |h,k| h[k] = SameXImplicants.new }
                implicants.each_value do |group|
                    group.sort! # Sort by number of one
                    size = group.size
                    # print "size = #{size}\n"
                    group.each_with_index do |imp0,i0|
                        # print "imp0 = #{imp0}, i0=#{i0}\n"
                        ((i0+1)..(size-1)).each do |i1|
                            # Get the next implicant
                            imp1 = group[i1]
                            # print "imp1 = #{imp1}, i1=#{i1}\n"
                            # No need to look further if the number of 1 of imp1
                            # is more than one larger than imp0's
                            break if imp1.count > imp0.count+1
                            # Try to merge
                            mrg = imp0.merge(imp1)
                            # print "mrg = #{mrg}\n"
                            # Can merge
                            if mrg then
                                mergeds[mrg.mask] << mrg
                                # Indicate than a merged happend
                                has_merged = true
                                # Mark the initial generators as not prime
                                imp0.prime = imp1.prime = false
                            end
                        end 
                        # Is the term prime?
                        if imp0.prime then
                            # print "imp0 is prime\n"
                            # Yes add it to the generators
                            generators << imp0
                        end
                    end
                end
                # print "mergeds=#{mergeds}\n"
                # Prepare the next iteration
                implicants = mergeds
            end while has_merged

            # print "generators with covers:\n"
            # generators.each {|gen| print gen,": ", gen.covers,"\n" }

            # Step 2: remove the redundancies
            
            # Select the generators using Petrick's method
            # For that purpose treat the generators as variables
            variables = generators.map {|gen| VarImp.new(gen) }
            
            # Group the variables by cover
            cover2gen = Hash.new { |h,k| h[k] = [] }
            variables.each do |var|
                # print "var=#{var}, implicant=#{var.implicant}, covers=#{var.implicant.covers}\n"
                var.implicant.covers.each { |cov| cover2gen[cov] << var }
            end
            # Convert this hierachical table to a product of sum
            # First the sum terms
            sums = cover2gen.each_value.map do |vars|
                # print "vars=#{vars}\n"
                if vars.size > 1 then
                    NodeOr.new(*vars.map {|var| NodeVar.new(var) })
                else
                    NodeVar.new(vars[0])
                end
            end
            # print "sums = #{sums.to_s}\n"
            # Then the product
            # expr = NodeAnd.new(*sums).uniq
            if sums.size > 1 then
                expr = NodeAnd.new(*sums).reduce
            else
                expr = sums[0]
            end
            # Convert it to a sum of product
            # print "expr = #{expr.to_s}\n"
            expr = expr.to_sum_product(true)
            # print "Now expr = #{expr.to_s} (#{expr.class})\n"
            # Select the smallest term (if several)
            if (expr.op == :or) then
                smallest = expr.min_by do |term|
                    term.op == :and ? term.size : 1
                end
            else
                smallest = expr
            end
            # The corresponding implicants are the selected generators
            if smallest.op == :and then
                selected = smallest.map {|term| term.variable.implicant }
            else
                selected = [ smallest.variable.implicant ]
            end

            # Sort by variable order
            selected.sort_by! { |imp| imp.bits }

            # print "Selected prime implicants are: #{selected}\n"
            # Generate the resulting tree
            variables = self.getVariables()
            # First generate the prime implicants trees
            selected.map! do |prime|
                # Generate the litterals 
                litterals = []
                prime.each.with_index do |c,i|
                    case c
                    when "0" then
                        litterals << NodeNot.new(NodeVar.new(variables[i]))
                    when "1" then litterals << NodeVar.new(variables[i])
                    end
                end
                # Generate the tree
                NodeAnd.new(*litterals)
            end
            # Then generate the final sum tree
            return NodeOr.new(*selected)
        end
    end
end
