#############################################################
# Logic tree classes: used for describing logic expressions #
#############################################################

require 'forwardable'

module LogicTools

    ## 
    # Represents a logical variable.
    class Variable

        include Comparable

        # The pool of variables
        @@variables = {}

        ## The current value of the variable (boolean).
        attr_reader :value

        ## Creates a new variable with +name+ (the value is set to false).
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

        #  Sets the variable to +value+ (boolean).
        def value=(value)
            if (value.respond_to?(:to_i))
                @value = value.to_i == 0 ? false : true
            else
                @value = value ? true : false
            end
        end

        ## Checks if variable +name+ exists.
        def Variable.exists?(name)
            return @@variables.has_key?(name.to_s)
        end

        ## Gets a variable by +name+. 
        #  If there is no such variable yet, creates it.
        def Variable.get(name)
            var = @@variables[name.to_s]
            # print "Got var=#{var.to_s} with value=#{var.value}\n" if var
            var = Variable.new(name) unless var
            return var
        end

        ## Converts to a string: actually returns a duplicate of the name
        #  of the variable.
        def to_s
            @name.dup
        end

        def inspect # :nodoc:
            to_s
        end

        ## Compares with another object using the name of the variable.
        def <=>(b)
            self.to_s <=> b.to_s
        end
    end

    ## 
    # Represents a node of a tree representing a logical expression.
    class Node

        include Enumerable

        ## Gets a array containing the variables of the tree sorted by name.
        def getVariables()
            result = self.getVariablesRecurse
            return result.flatten.uniq.sort
        end

        ## Gets the operator.
        #
        #  Default: +nil+ (none).
        def op
            nil
        end

        ## Gets number of children.
        #
        #  Default: +0+ (none).
        def size
            0
        end

        ## Iterates on each line of the truth table obtained from the tree
        #  rooted by current node.
        #
        #  Iteration parameters (for the current line of the truth table):
        #  * +vars+: the variables of the expression 
        #  * +val+:  the value of the expression
        def each_line
            # No block given? Return an enumerator.
            return to_enum(:each_line) unless block_given?

            # Block given? Apply it.
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

        ## Iterates over each minterm of the tree rooted from current node.
        #
        #  Iteration parameters:
        #  * +vars+: the variables of the expression
        def each_minterm
            # No block given? Return an enumerator.
            return to_enum(:each_minterm) unless block_given?

            # Block given? Apply it.
            each_line { |vars,val| yield(vars) if val }
        end

        ## Iterates over each maxterm of the tree rooted from current node.
        #
        #  Iteration parameters:
        #  * +vars+: the variables of the expression
        def each_maxterm
            # No block given? Return an enumerator.
            return to_enum(:each_maxterm) unless block_given?

            # Block given? Apply it.
            each_line do |vars,val|
                unless val then
                    vars.each { |var| var.value = !var.value }
                    yield(vars)
                end
            end
        end

        ## Iterate over the children.
        def each
            # No block given? Return an enumerator.
            return to_enum(:each) unless block_given?
            # Block given? No child, so nothing to do anyway...
        end

        ## Generates the equivalent standard conjunctive form.
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

        ## Generates the equivalent standard disjunctive form.
        def to_std_disjunctive
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

        ## Creates a new tree where the *and*, *or* or *not* operator of
        #  the current node is flattened.
        #
        #  Default: simply duplicates the node.
        def flatten
            return self.dup
        end

        ## Creates a new tree where all the *and*, *or* and *not* operators 
        #  from the current node are flattened.
        #
        #  Default: simply duplicate.
        def flatten_deep
            return self.dup
        end

        ## Creates a new tree where the current node is distributed over +node+
        #  according to the +dop+ operator.
        def distribute(dop,node)
            fop = dop == :and ? :or : :and
            # print "dop=#{dop}, fop=#{fop}, node.op=#{node.op}\n"
            if (node.op == dop) then
                # Same operator: merge self in node
                return NodeNary.make(dop, self, *node)
            elsif (node.op == fop) then
                # Opposite operator: can distribute
                nchildren = node.map do |child|
                    NodeNary.make(dop,child,self).flatten
                end
                return NodeNary.make(fop,*nchildren).flatten
            else
                # Unary operator: simple product
                return NodeNary.make(dop, self, node)
            end
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false)
            return self.dup
        end

        def inspect # :nodoc:
            to_s
        end

        ## Converts to a symbol.
        #
        #  There is exactly one symbol per possible tree.
        def to_sym
            to_s.to_sym
        end

        def hash # :nodoc:
            to_sym.hash
        end
        def eql?(val) # :nodoc:
            self == val
        end
    end

    
    ## 
    # Represents a value node.
    class NodeValue < Node

        protected

        ## Creates a node by +value+.
        def initialize(value) # :nodoc:
            @value = value
            @sym = @value.to_s.to_sym
        end

        public

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def getVariablesRecurse() # :nodoc:
            return [ ]
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(NodeValue)
            return self.eval() == node.eval()
        end

        ## Computes the value of the node.
        def eval
            return @value
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            return @sym
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return @value.to_s
        end
    end

    ## 
    # Represents a true node.
    class NodeTrue < NodeValue
        ## Creates as a NodeValue whose value is true.
        def initialize
            super(true)
        end
    end

    ## 
    # Represents a false node
    class NodeFalse < NodeValue
        ## Creates as a NodeValue whose value is false.
        def initialize
            super(false)
        end
    end


    ## 
    # Represents a variable node.
    class NodeVar < Node

        ## The variable held by the node.
        attr_reader :variable

        ## Creates a node with variable +name+.
        def initialize(name)
            @variable = Variable.get(name)
            @sym = @variable.to_s.to_sym
        end

        ## Computes the value of the node.
        def eval()
            return @variable.value
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            return @sym
        end

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def getVariablesRecurse() # :nodoc:
            return [ @variable ]
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(NodeVar)
            return self.variable == node.variable
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return variable.to_s
        end
    end

    ## 
    # Represents an operator node with multiple children.
    class NodeNary < Node 
        extend Forwardable

        attr_reader :op

        protected
        ## Creates a node with operator +op+ and +children+.
        def initialize(op,*children) # :nodoc:
            # Check the children
            children.each do |child|
                unless child.is_a?(Node) then
                    raise ArgumentError.new("Not a valid class for a child: "+
                                            "#{child.class}")
                end
            end
            # Children are ok
            @op = op.to_sym
            @children = children
            @sym = self.to_s.to_sym
        end

        public
        ## Creates a node with operator +op+ and +children+ (factory method).
        def NodeNary.make(op,*children)
            case op
            when :or 
                return NodeOr.new(*children)
            when :and
                return NodeAnd.new(*children)
            else 
                raise ArgumentError.new("Not a valid operator: #{op}")
            end
        end


        # Also acts as an array of nodes
        def_delegators :@children, :[], :empty?, :size

        ## Iterates over the children.
        def each(&blk) # :nodoc:
            # No block given? Return an enumerator.
            return to_enum(:each) unless blk

            # Block given? Apply it.
            @children.each(&blk)
            return self
        end

        ## Creates a new node whose childrens are sorted.
        def sort
            return NodeNary.make(@op,*@children.sort_by {|child| child.to_sym })
        end

        ## Creates a new node without duplicate in the children.
        def uniq(&blk)
            if blk then
                nchildren = @children.uniq(&blk)
            else
                nchildren = @children.uniq { |child| child.to_sym }
            end
            if nchildren.size == 1 then
                return nchildren[0]
            else
                return NodeNary.make(@op,*nchildren)
            end
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            return @sym
        end

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def getVariablesRecurse() # :nodoc:
            return @children.reduce([]) do |res,child|
                res.concat(child.getVariablesRecurse)
            end
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(Node)
            return false unless self.op == node.op
            # There is no find_with_index!
            # return ! @children.find_with_index {|child,i| child != node[i] }
            @children.each_with_index do |child,i|
                return false if child != node[i]
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
        #     @children.each do |term|
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
        #     nchildren = terms.values
        #     # Avoid doublons
        #     nchildren.uniq!
        #     # Generate the result
        #     if (nchildren.size == 1)
        #         return nchildren[0]
        #     else
        #         return NodeNary.make(@op,*nchildren)
        #     end
        # end

        ## Reduces a node: remove its redundancies using the absbortion rules.
        #
        #  --
        #  TODO consider the X~X and X+~X cases.
        def reduce
            # The operator used for the factors
            fop = @op == :and ? :or : :and
            # Gather the terms converted to a sorted string for fast
            # comparison
            terms = @children.map do |child|
                if (child.op == fop) then
                    [ child, child.sort.to_s ]
                else
                    [ child, child.to_s ]
                end
            end
            nchildren = []
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
                nchildren << term0[0] unless skipped # Term has not been skipped
            end
            # Avoid duplicates
            nchildren.uniq!
            # Generate the result
            if (nchildren.size == 1)
                return nchildren[0]
            else
                return NodeNary.make(@op,*nchildren)
            end
        end

        ## Flatten ands, ors and nots.
        def flatten # :nodoc:
            return NodeNary.make(@op,*(@children.reduce([]) do |nchildren,child|
                if (child.op == self.op) then
                    nchildren.push(*child)
                else
                    nchildren << child
                end
            end)).reduce
        end

        ## Creates a new tree where all the *and*, *or* and *not* operators 
        #  from the current node are flattened.
        #
        #  Default: simply duplicate.
        def flatten_deep # :nodoc:
            return NodeNary.make(@op,*(@children.reduce([]) do |nchildren,child|
                child = child.flatten_deep
                if (child.op == self.op) then
                    nchildren.push(*child)
                else
                    nchildren << child
                end
            end)).reduce
        end

        ## Creates a new tree where the current node is distributed over +node+
        #  according to the +dop+ operator.
        def distribute(dop,node) # :nodoc:
            fop = dop == :and ? :or : :and
            # print "dop=#{dop} fop=#{fop} self.op=#{@op}\n"
            if (@op == dop) then
                # Self operator is dop: merge node in self
                return NodeNary.make(dop,*self,node).flatten
            else
                # self operator if fop
                if (node.op == fop) then
                    # node operator is also fop: (a+b)(c+d) or ab+cd case
                    nchildren = []
                    self.each do |child0|
                        node.each do |child1|
                            # print "child0=#{child0}, child1=#{child1}\n"
                            nchildren << 
                                NodeNary.make(dop, child0, child1).flatten
                            # print "nchildren=#{nchildren}\n"
                        end
                    end
                    return NodeNary.make(fop,*nchildren).flatten
                else
                    # node operator is not fop: (a+b)c or ab+c case
                    nchildren = self.map do |child|
                        NodeNary.make(dop,child,node).flatten
                    end
                    return NodeNary.make(fop,*nchildren).flatten
                end
            end
        end
    end

    
    ## 
    # Represents an AND node
    class NodeAnd < NodeNary

        #  Creates a new AND node with +children+. 
        def initialize(*children)
            super(:and,*children)
        end

        ## Duplicates the node.
        def dup # :nodoc:
            return NodeAnd.new(@children.map(&:dup))
        end

        ## Computes the value of the node.
        def eval()
            return !@children.any? {|child| child.eval() == false }
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false) # :nodoc:
            # Flatten if required
            node = flattened ? self : self.flatten_deep
            # print "node = #{node}\n"
            # Convert each child to sum of product
            nchildren = node.map {|child| child.to_sum_product(true) }
            # print "nchildren = #{nchildren}\n"
            # Distribute
            while(nchildren.size>1)
                dist = []
                nchildren.each_slice(2) do |left,right|
                    # print "left=#{left}, right=#{right}\n"
                    if right then
                        dist << (left.op == :or ? left.distribute(:and,right) :
                                                  right.distribute(:and,left))
                    else
                        dist << left
                    end
                end
                # print "dist=#{dist}\n"
                nchildren = dist
            end
            # print "Distributed nchildren=#{nchildren}\n"
            # Generate the or
            if (nchildren.size > 1)
                return NodeOr.new(*nchildren)
            else
                return nchildren[0]
            end
        end

        ## Convert to a string.
        def to_s # :nodoc:
            return @str if @str
            @str = ""
            # Convert the children to a string
            @children.each do |child|
                if (child.op == :or) then
                    # Yes, need parenthesis
                    @str << ( "(" + child.to_s + ")" )
                else
                    @str << child.to_s
                end
            end
            return @str
        end
    end


    ## 
    # Represents an OR node
    class NodeOr < NodeNary

        #  Creates a new OR node with +children+. 
        def initialize(*children)
            super(:or,*children)
        end

        ## Duplicates the node.
        def dup # :nodoc:
            return NodeOr.new(@children.map(&:dup))
        end

        ## Computes the value of the node.
        def eval
            return @children.any? {|child| child.eval() == true }
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false) # :nodoc:
            return NodeOr.new(
                *@children.map {|child| child.to_sum_product(flatten) } )
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return @str if @str
            # Convert the children to string a insert "+" between them
            @str = @children.join("+")
            return @str
        end
    end



    ##
    # Represents an unary node.
    class NodeUnary < Node
        attr_reader :op, :child

        ## Creates a node with operator +op+ and a +child+.
        def initialize(op,child)
            if !child.is_a?(Node) then
                raise ArgumentError.new("Not a valid object for child.")
            end
            @op = op.to_sym
            @child = child
            @sym = self.to_s.to_sym
        end

        ## Gets the number of children.
        def size # :nodoc:
            1
        end

        # ## Set the child node
        # #  @param child the node to set
        # def child=(child)
        #     # Checks it is a valid object
        #     if !child.is_a?(Node) then
        #         raise ArgumentError.new("Not a valid object for child.")
        #     else
        #         @child = child
        #     end
        # end

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def getVariablesRecurse() # :nodoc:
            return @child.getVariablesRecurse
        end

        ## Iterates over the children.
        def each # :nodoc:
            # No block given? Return an enumerator.
            return to_enum(:each) unless block_given?

            # Block given? Apply it.
            yield(@child)
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(Node)
            return false unless self.op == n.op
            return self.child == node.child
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            return @sym
        end
    end

    ## 
    # Represents a NOT node.
    class NodeNot < NodeUnary
        ## Creates a NOT node with a +child+. 
        def initialize(child)
            super(:not,child)
        end

        ## Duplicates the node.
        def dup # :nodoc:
            return NodeNot.new(@child.dup)
        end

        ## Computes the value of the node.
        def eval # :nodoc:
            return !child.eval
        end

        ## Creates a new tree where the *and*, *or* or *not* operator of
        #  the current node is flattened.
        #
        #  Default: simply duplicates the node.
        def flatten # :nodoc:
            nchild = @child.flatten
            if nchild.op == :not then
                return nchild.child
            else
                return NodeNot.new(nchild)
            end
        end

        ## Creates a new tree where all the *and*, *or* and *not* operators 
        #  from the current node are flattened.
        #
        #  Default: simply duplicate.
        def flatten_deep # :nodoc:
            nchild = @child.flatten_deep
            if nchild.op == :not then
                return nchild.child
            else
                return NodeNot.new(child)
            end
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false) # :nodoc:
            return NodeNot.new(@child.to_sum_product(flatten))
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return @str if @str
            # Is the child a binary node?
            if child.op == :or || child.op == :and then
                # Yes must put parenthesis
                @str = "~(" + child.to_s + ")"
            else
                # No
                @str = "~" + child.to_s
            end
            return @str
        end
    end

end
