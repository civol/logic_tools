###################################################################
# Logic tree classes extension for simplifying a logic expression #
# using the Quine-Mc Cluskey method                               #
###################################################################


require 'set'


module LogicTools


    ## Converts the array of variables +var+ to a bit vector according to
    #  their values
    def vars2int(vars)
        res = ""
        vars.each_with_index do |var,i|
            res[i] = var.value ? "1" : "0"
        end
        res
    end





    ##
    # Represents a logic implicant
    class Implicant
        include Enumerable

        ## The positions of the *X* in the implicant.
        attr_reader :mask
        ## The bit vector of the implicant.
        attr_reader :bits
        ## The number of *1* of the implicant.
        attr_reader :count
        ## The bit values covered by the implicant.
        attr_reader :covers
        ## Tell if the implicant is prime or not.
        attr_reader :prime   
        ## The variable associated with the implicant
        #  Do not interfer at all with the class, so
        #  public and fully accessible
        attr_accessor :var    
        
        protected
        attr_writer :covers
        public

        ## Creates a new implicant from +base+.
        #
        #  Argument +base+ can be either another implicant or a bit string.
        def initialize(base)
            if base.is_a?(Implicant)
                @covers = base.covers.dup
                @bits = base.bits.dup
                @mask = base.mask.dup
                @count = base.count
            else
                @bits = base.to_s
                unless @bits.match(/^[01]*$/)
                    raise "Invalid bit string for an initial implicant: "+ @bits
                end
                @mask = " " * @bits.size
                @count = @bits.count("1")
                @covers = [ @bits ]
            end
            @prime = true # By default assumed prime
        end

        ## Converts to a string
        def to_s # :nodoc:
            @bits
        end

        def inspect #:nodoc:
            @bits.dup
        end

        ## Sets the prime status to +st+ (true or false).
        def prime=(st)
            @prime = st ? true : false
        end

        ## Iterates over the bits of the implicant.
        def each(&blk)
            @bits.each_char(&blk)
        end

        ## Compares with +implicant+
        def ==(implicant) # :nodoc:
            @bits == implicant.to_s
        end
        def <=>(implicant) #:nodoc:
            @bits <=> implicant.to_s
        end

        ## duplicates the implicant.
        def dup # :nodoc:
            Implicant.new(self)
        end

        ## Gets the value of bit +i+.
        def [](i)
            @bits[i]
        end

        ## Sets the value of bit +i+ to +b+.
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


        ## Creates a new implicant merging current implicant with +imp+.
        def merge(implicant)
            # Has implicant the same mask?
            return nil unless implicant.mask == @mask
            # First look for a 1-0 or 0-1 difference
            found = nil
            @bits.each_char.with_index do |b0,i|
                b1 = implicant.bits[i]
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
                merged.covers = @covers | implicant.covers
                return merged
            end
            # No merge
            return nil
        end
    end


    ##
    # Represents a group of implicants with only singletons, sortable
    # by number of ones.
    class SameXImplicants
        include Enumerable

        ## Creates a group of implicants.
        def initialize
            @implicants = []
            @singletons =  Set.new # Set used for ensuring each implicant is
                                   # present only once in the group
        end

        ## Gets the number of implicants of the group.
        def size
            @implicants.size
        end

        ## Iterates over the implicants of the group.
        def each(&blk)
            @implicants.each(&blk)
        end

        ## Gets implicant +i+.
        def [](i)
            @implicants[i]
        end

        ## Adds +implicant+ to the group.
        def add(implicant)
            # Nothing to do if +implicant+ is already present.
            return if @singletons.include?(implicant.bits)
            @implicants << implicant
            @singletons.add(implicant.bits.dup)
        end

        alias :<< :add

        ## Sort the implicants by number of ones.
        def sort!
            @implicants.sort_by! {|implicant| implicant.count }
        end

        ## Converts to a string
        def to_s # :nodoc:
            @implicants.to_s
        end

        def inspect # :nodoc:
            to_s
        end
    end

    ## 
    #  Describes a pseudo variable associated to an implicant.
    #
    #  Used for the Petrick's method
    class VarImp < Variable
        @@base = 0 # The index of the VarImp for building the variable names

        ## The implicant the pseudo variable is associated to.
        attr_reader :implicant

        ## Creates a pseudo variable assoctiated to an +implicant+.
        def initialize(implicant)
            # Create the name of the variable
            name = nil
            begin
                name = "P" + @@base.to_s
                @@base += 1
            end while Variable.exists?(name)
            # Create the variable
            super(name)
            # Associate it with the implicant
            @implicant = implicant
            implicant.var = self
        end
    end



    ## Enhances the Node class with expression simplifying.
    class Node
        
        ## Generates an equivalent but simplified representation of the
        #  expression represented by the tree rooted by the current node.
        #
        #  Uses the Quine-Mc Cluskey method.
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
                implicant = Implicant.new(term)
                implicants[implicant.mask] << implicant
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
                    group.each_with_index do |implicant0,i0|
                        # print "implicant0 = #{implicant0}, i0=#{i0}\n"
                        ((i0+1)..(size-1)).each do |i1|
                            # Get the next implicant
                            implicant1 = group[i1]
                            # print "implicant1 = #{implicant1}, i1=#{i1}\n"
                            # No need to look further if the number of 1 of 
                            # implicant1 is more than one larger than 
                            # implicant0's
                            break if implicant1.count > implicant0.count+1
                            # Try to merge
                            mrg = implicant0.merge(implicant1)
                            # print "mrg = #{mrg}\n"
                            # Can merge
                            if mrg then
                                mergeds[mrg.mask] << mrg
                                # Indicate than a merged happend
                                has_merged = true
                                # Mark the initial generators as not prime
                                implicant0.prime = implicant1.prime = false
                            end
                        end 
                        # Is the term prime?
                        if implicant0.prime then
                            # print "implicant0 is prime\n"
                            # Yes add it to the generators
                            generators << implicant0
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
            selected.sort_by! { |implicant| implicant.bits }

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
