#############################################################
# Logic tree classes: used for describing logic expressions #
#############################################################

require 'forwardable'

module LogicTools

    ## A logical variable
    class Variable

        include Comparable

        ## The pool of variables
        @@variables = {}

        attr_reader :value

        ## Initialize with a name (the value is set to false)
        #  @param name the name of the variable
        def initialize(name)
            if @@variables.key?(name.to_s)
                raise "Variable already present."
            end
            # print "New variable with name=#{name}\n"
            @name = name.to_s
            @value = false
            # Add the variable to the pool
            @@variables[name.to_s] = self
        end

        ## Set the value
        #  @param value the value to set
        def value=(value)
            if (value.respond_to?(:to_i))
                @value = value.to_i == 0 ? false : true
            else
                @value = value ? true : false
            end
        end

        ## Checks if a variables exists
        def Variable.exists?(name)
            return @@variables.has_key?(name.to_s)
        end

        ## Get a variable by name, if not existing creates it.
        #  @param name the name of the variable
        def Variable.get(name)
            var = @@variables[name.to_s]
            # print "Got var=#{var.to_s} with value=#{var.value}\n" if var
            var = Variable.new(name) unless var
            return var
        end

        ## Convert to a string
        def to_s
            @name.dup
        end

        ## For print
        def inspect
            to_s
        end

        # For comparison
        def <=>(b)
            self.to_s <=> b.to_s
        end
    end

    ## A logical tree node
    class Node
        include Enumerable

        ## Get the variables of the tree
        #  @return the variables into an array, sorted by name
        def getVariables()
            result = self.getVariablesRecurse
            return result.flatten.uniq.sort
        end

        ## Get the operator if any
        def op
            nil
        end

        ## Get the size (number of sons)
        #  Default: 0
        def size
            0
        end

        ## Iterate on each truth table line.<br>
        #  Iteration parameters:
        #  @param vars the variables of the expression
        #  @param val the value
        def each_line
            # Get the variables
            vars = self.getVariables
            # Compute the number of iterations
            nlines = 2**vars.size
            # Generates each bit value for the variables and the
            # correspong node value for iterating on it
            nlines.times do |line|
                vars.each_with_index do |var,i|
                    val = line[vars.size-i-1]
                    var.value = val
                end
                # Apply the block
                yield(vars,self.eval)
            end
        end

        ## Iterate over each minterm.<br>
        #  Iteration parameters:
        #  @param vars the variables of the expression
        def each_minterm
            each_line { |vars,val| yield(vars) if val }
        end

        ## Iterate over each maxterm.<br>
        #  Iteration parameters:
        #  @param vars the variables of the expression
        def each_maxterm
            each_line do |vars,val|
                unless val then
                    vars.each { |var| var.value = !var.value }
                    yield(vars)
                end
            end
        end

        ## Iterate on the sons (if any, by default: none)
        def each
        end

        ## Generates the equivalent standard conjunctive form 
        def to_std_conjunctive
            # Generate each minterm tree
            minterms = []
            each_minterm do |vars|
                vars = vars.map do |var|
                    var = NodeVar.new(var)
                    var = NodeNot.new(var) unless var.eval
                    var
                end
                # Create the term
                term = vars.size == 1 ? vars[0] : NodeAnd.new(*vars)
                # Add the term
                minterms << term
            end
            # Conjunct them
            return minterms.size == 1 ? minterms[0] : NodeOr.new(*minterms)
        end

        ## Generates the equivalent standard disjonctive form
        def to_std_disjonctive
            # Generate each maxterm tree
            maxterms = []
            each_maxterm do |vars|
                vars = vars.map do |var|
                    var = NodeVar.new(var)
                    var = NodeNot.new(var) unless var.eval
                    var
                end
                # Create the term
                term = vars.size == 1 ? vars[0] : NodeOr.new(*vars)
                # Add the term
                maxterms << term
            end
            # Disjunct them
            return maxterms.size == 1 ? maxterms[0] : NodeAnd.new(*maxterms)
        end

        ## Flatten ands, ors and nots
        #  Default: simply duplicate
        def flatten
            return self.dup
        end

        ## Flatten hierachical ands, ors and nots
        #  @return the new tree
        #  Default: simply duplicate
        def flatten_deep
            return self.dup
        end

        ## Distribute over a given operator
        #  @param dop the operator to distribute over
        #  @param node the node to distribute with
        # Default distribution: self is unary
        def distribute(dop,node)
            fop = dop == :and ? :or : :and
            # print "dop=#{dop}, fop=#{fop}, node.op=#{node.op}\n"
            if (node.op == dop) then
                # Same operator: merge self in node
                return NodeNary.make(dop, self, *node)
            elsif (node.op == fop) then
                # Opposite operator: can distribute
                nsons = node.map do |son|
                    NodeNary.make(dop,son,self).flatten
                end
                return NodeNary.make(fop,*nsons).flatten
            else
                # Unary operator: simple product
                return NodeNary.make(dop, self, node)
            end
        end

        ## Convert to a sum of product
        #  @param flattened tell if the tree is already flattend
        #  @return the conversion result
        def to_sum_product(flattened = false)
            return self.dup
        end

        ## For print
        def inspect
            to_s
        end

        ## Convert to a symbol:
        #  Default: to_s.to_sym
        def to_sym
            to_s.to_sym
        end

        ## For hash
        def hash
            to_sym.hash
        end
        def eql?(val)
            self == val
        end
    end

    # A Value node
    class NodeValue < Node

        protected
        ## Build with a value
        #  @param value the value
        def initialize(value)
            @value = value
            @sym = @value.to_s.to_sym
        end
        public

        ## Get the variables, recursively, without postprocessing
        #  @return the variables into sets of arrays with possible doublon
        def getVariablesRecurse()
            return [ ]
        end

        ## Compare with another node
        #  @param n the node to compare with
        def ==(n)
            return false unless n.is_a?(NodeValue)
            return self.eval() == n.eval()
        end

        ## Evaluates
        def eval
            return @value
        end

        ## Convert to a symbol
        def to_sym
            return @sym
        end

        ## Converts to a string
        def to_s
            return @value.to_s
        end
    end

    # A true node
    class NodeTrue < NodeValue
        ## Intialize as a NodeValue whose value is true
        def initialize
            super(true)
        end
    end

    # A false node
    class NodeFalse < NodeValue
        ## Intialize as a NodeValue whose value is false
        def initialize
            super(false)
        end
    end

    # A variable node
    class NodeVar < Node
        attr_reader :variable

        ## Initialize with the variable name
        #  @param name the name of the variable
        def initialize(name)
            @variable = Variable.get(name)
            @sym = @variable.to_s.to_sym
        end

        ## Evaluates the node
        def eval()
            return @variable.value
        end

        ## Convert to a symbol
        def to_sym
            return @sym
        end

        ## Get the variables, recursively, without postprocessing
        #  @return the variables into sets of arrays with possible doublon
        def getVariablesRecurse()
            return [ @variable ]
        end

        ## Compare with another node
        #  @param n the node to compare with
        def ==(n)
            return false unless n.is_a?(NodeVar)
            return self.variable == n.variable
        end

        ## Converts to a string
        def to_s
            return variable.to_s
        end
    end

    # A binary node
    class NodeNary < Node 
        extend Forwardable
        include Enumerable

        attr_reader :op

        protected
        ## Initialize with the operator
        #  @param op the operator name
        #  @param sons the sons
        def initialize(op,*sons)
            # Check the sons
            sons.each do |son|
                unless son.is_a?(Node) then
                    raise ArgumentError.new("Not a valid class for a son: "+
                                            "#{son.class}")
                end
            end
            # Sons are ok
            @op = op.to_sym
            @sons = sons
            @sym = self.to_s.to_sym
        end

        public
        ## Create a new nary node
        #  @param op the operator name
        #  @param sons the sons
        def NodeNary.make(op,*sons)
            case op
            when :or 
                return NodeOr.new(*sons)
            when :and
                return NodeAnd.new(*sons)
            else 
                raise ArgumentError.new("Not a valid operator: #{op}")
            end
        end


        # Also acts as an array of nodes
        def_delegators :@sons, :[], :empty?, :size
        def each(&blk)
            @sons.each(&blk)
            return self
        end
        # def sort_by!(&blk)
        #     @sons.sort_by!(&blk)
        #     return self
        # end
        # def sort!
        #     @sons.sort_by! {|son| son.sym }
        #     return self
        # end
        def sort
            return NodeNary.make(@op,*@sons.sort_by {|son| son.to_sym })
        end

        ##  Create a new node without doublons
        def uniq(&blk)
            if blk then
                nsons = @sons.uniq(&blk)
            else
                nsons = @sons.uniq { |son| son.to_sym }
            end
            if nsons.size == 1 then
                return nsons[0]
            else
                return NodeNary.make(@op,*nsons)
            end
        end

        ## Convert to a symbol
        def to_sym
            return @sym
        end

        ## Get the variables, recursively, without postprocessing
        #  @return the variables into sets of arrays with possible doublon
        def getVariablesRecurse()
            return @sons.reduce([]) do |res,son|
                res.concat(son.getVariablesRecurse)
            end
        end

        ## Compare with another node
        #  @param n the node to compare with
        def ==(n)
            return false unless n.is_a?(Node)
            return false unless self.op == n.op
            # There is no find_with_index!
            # return ! @sons.find_with_index {|son,i| son != n[i] }
            @sons.each_with_index do |son,i|
                return false if son != n[i]
            end
            return true
        end

        # WRONG
        ## Reduce a node: remove its redudancies using absbortion rules
        #  NOTE: NEED to CONSIDER X~X and X+~X CASES
        # def reduce
        #     # The operator used for the factors
        #     fop = @op == :and ? :or : :and
        #     # Gather the terms by factor
        #     terms = Hash.new {|h,k| h[k] = [] }
        #     @sons.each do |term|
        #         if (term.op == fop) then
        #             # There are factors
        #             term.each { |fact| terms[fact] << term }
        #         else
        #             # There term is singleton
        #             terms[term] << term
        #         end
        #     end
        #     # Keep only the shortest term per factor
        #     terms.each_key {|k| terms[k] = terms[k].min_by {|term| term.size} }
        #     nsons = terms.values
        #     # Avoid doublons
        #     nsons.uniq!
        #     # Generate the result
        #     if (nsons.size == 1)
        #         return nsons[0]
        #     else
        #         return NodeNary.make(@op,*nsons)
        #     end
        # end
        ## Reduce a node: remove its redudancies using absbortion rules
        #  NOTE: NEED to CONSIDER X~X and X+~X CASES
        def reduce
            # The operator used for the factors
            fop = @op == :and ? :or : :and
            # Gather the terms converted to a sorted string for fast
            # comparison
            terms = @sons.map do |son|
                if (son.op == fop) then
                    [ son, son.sort.to_s ]
                else
                    [ son, son.to_s ]
                end
            end
            nsons = []
            # Keep only the terms that do not contain another one
            terms.each_with_index do |term0,i|
                skipped = false
                terms.each_with_index do |term1,j|
                    next if (i==j) # Same term
                    if (term0[1].include?(term1[1])) and term0[1]!=term1[1] then
                        # term0 contains term1 but is different, skip it
                        skipped = true
                        break
                    end
                end
                nsons << term0[0] unless skipped # Term has not been skipped
            end
            # Avoid doublons
            nsons.uniq!
            # Generate the result
            if (nsons.size == 1)
                return nsons[0]
            else
                return NodeNary.make(@op,*nsons)
            end
        end

        ## Flatten ands, ors and nots
        #  Default: simply duplicate
        def flatten
            return NodeNary.make(@op,*(@sons.reduce([]) do |nsons,son|
                if (son.op == self.op) then
                    nsons.push(*son)
                else
                    nsons << son
                end
            end)).reduce
        end

        ## Flatten hierachical ands, ors and nots, removing redudancies
        #  @return the new tree
        def flatten_deep
            return NodeNary.make(@op,*(@sons.reduce([]) do |nsons,son|
                son = son.flatten_deep
                if (son.op == self.op) then
                    nsons.push(*son)
                else
                    nsons << son
                end
            end)).reduce
        end

        ## Distribute over a given operator
        #  @param dop the operator to distribute over
        #  @param node the node to distribute with
        def distribute(dop,node)
            fop = dop == :and ? :or : :and
            # print "dop=#{dop} fop=#{fop} self.op=#{@op}\n"
            if (@op == dop) then
                # Self operator is dop: merge node in self
                return NodeNary.make(dop,*self,node).flatten
            else
                # self operator if fop
                if (node.op == fop) then
                    # node operator is also fop: (a+b)(c+d) or ab+cd case
                    nsons = []
                    self.each do |son0|
                        node.each do |son1|
                            # print "son0=#{son0}, son1=#{son1}\n"
                            nsons << NodeNary.make(dop, son0, son1).flatten
                            # print "nsons=#{nsons}\n"
                        end
                    end
                    return NodeNary.make(fop,*nsons).flatten
                else
                    # node operator is not fop: (a+b)c or ab+c case
                    nsons = self.map do |son|
                        NodeNary.make(dop,son,node).flatten
                    end
                    return NodeNary.make(fop,*nsons).flatten
                end
            end
        end
    end

    # A and node
    class NodeAnd < NodeNary
        ## Initialize by building a new nary node whose operator is and
        #  @param sons the sons
        def initialize(*sons)
            super(:and,*sons)
        end

        ## Duplicates the node
        def dup
            return NodeAnd.new(@sons.map(&:dup))
        end

        ## Evaluate the node
        def eval()
            return !@sons.any? {|son| son.eval() == false }
        end

        ## Convert to a sum of product
        #  @param flattened tell of the tree is already flatttend
        #  @return the conversion result
        def to_sum_product(flattened = false)
            # Flatten if required
            node = flattened ? self : self.flatten_deep
            # print "node = #{node}\n"
            # Convert each son to sum of product
            nsons = node.map {|son| son.to_sum_product(true) }
            # print "nsons = #{nsons}\n"
            # Distribute
            while(nsons.size>1)
                dist = []
                nsons.each_slice(2) do |left,right|
                    # print "left=#{left}, right=#{right}\n"
                    dist << (right ? left.distribute(:and,right) : left)
                end
                # print "dist=#{dist}\n"
                nsons = dist
            end
            # print "Distributed nsons=#{nsons}\n"
            # Generate the or
            if (nsons.size > 1)
                return NodeOr.new(*nsons)
            else
                return nsons[0]
            end
        end

        ## Converts to a string
        def to_s
            return @str if @str
            @str = ""
            # Convert the sons to a string
            @sons.each do |son|
                if (son.op == :or) then
                    # Yes, need parenthesis
                    @str << ( "(" + son.to_s + ")" )
                else
                    @str << son.to_s
                end
            end
            return @str
        end
    end


    # A or node
    class NodeOr < NodeNary
        ## Initialize by building a new nary node whose operator is or
        #  @param sons the sons
        def initialize(*sons)
            super(:or,*sons)
        end

        ## Duplicates the node
        def dup
            return NodeOr.new(@sons.map(&:dup))
        end

        ## Evaluate the node
        def eval
            return @sons.any? {|son| son.eval() == true }
        end

        ## Convert to a sum of product
        #  @param flattened tell of the tree is already flatttend
        #  @return the conversion result
        def to_sum_product(flattened = false)
            return NodeOr.new(*@sons.map {|son| son.to_sum_product(flatten) })
        end

        ## Converts to a string
        def to_s
            return @str if @str
            # Convert the sons to string a insert "+" between them
            @str = @sons.join("+")
            return @str
        end
    end



    # An unary node
    class NodeUnary < Node
        attr_reader :op, :son

        ## Initialize with the operator
        #  @param op the operator name
        #  @param son the son node
        def initialize(op,son)
            if !son.is_a?(Node) then
                raise ArgumentError.new("Not a valid object for son.")
            end
            @op = op.to_sym
            @son = son
            @sym = self.to_s.to_sym
        end

        ## Get the size (number of sons)
        def size
            1
        end

        # ## Set the son node
        # #  @param son the node to set
        # def son=(son)
        #     # Checks it is a valid object
        #     if !son.is_a?(Node) then
        #         raise ArgumentError.new("Not a valid object for son.")
        #     else
        #         @son = son
        #     end
        # end

        ## Get the variables in an array recursively
        #  @return the variables into an array with possible doublon
        def getVariablesRecurse()
            return @son.getVariablesRecurse
        end

        ## Iterate on the sons
        def each
            yield(@son)
        end

        ## Compare with another node
        #  @param n the node to compare with
        def ==(n)
            return false unless n.is_a?(Node)
            return false unless self.op == n.op
            return self.son == n.son
        end

        ## Convert to a symbol
        def to_sym
            return @sym
        end
    end

    # A not node
    class NodeNot < NodeUnary
        ## Initialize by building a new unary node whose operator is not
        #  @param the son
        def initialize(son)
            super(:not,son)
        end

        ## Duplicates the node
        def dup
            return NodeNot.new(@son.dup)
        end

        ## Evaluate the node
        def eval
            return !son.eval
        end

        ## Flatten ands, ors and nots
        #  Default: simply duplicate
        def flatten
            if nson.op == :not then
                return nson
            else
                return NodeNot.new(nson)
            end
        end

        ## Flatten hierachical ands, ors and nots
        #  @return the new tree
        def flatten_deep
            nson = @son.flatten_deep
            if nson.op == :not then
                return nson
            else
                return NodeNot.new(nson)
            end
        end

        ## Convert to a sum of product
        #  @param flattened tell of the tree is already flatttend
        #  @return the conversion result
        def to_sum_product(flattened = false)
            return NodeNot.new(@son.to_sum_product(flatten))
        end

        ## Converts to a string
        def to_s
            return @str if @str
            # Is the son a binary node?
            if son.op == :or || son.op == :and then
                # Yes must put parenthesis
                @str = "~(" + son.to_s + ")"
            else
                # No
                @str = "~" + son.to_s
            end
            return @str
        end
    end

end
