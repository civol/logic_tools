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

        alias dup clone

        ## Gets a array containing the variables of the tree sorted by name.
        def get_variables()
            result = self.get_variablesRecurse
            return result.flatten.uniq.sort
        end

        ## Tells if the node is a parent.
        #
        #  Default: +false+.
        def is_parent?
            return false
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

        ## Evalutes the tree on a binary +input+.
        def eval_input(input)
            self.get_variables.each_with_index do |var,i|
                val = input[vars.size-i-1]
                var.value = val
            end
            return self.eval
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
            vars = self.get_variables
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
            # print "flatten_deep #1 with self=#{self}\n"
            return self.dup
        end

        ## Reduce the node by removing redundancy from it.
        #
        #  NOTE: this is not the same purpose a Enumerable::reduce.
        def reduce
            # By default, no possible reduction.
            self.clone
        end

        ## Creates a new tree where the current node is distributed over +node+
        #  according to the +dop+ operator.
        def distribute(dop,node)
            fop = dop == :and ? :or : :and
            if (node.op == dop) then
                # Same operator: merge self in node
                return NodeNary.make(dop, self, *node)
            elsif (node.op == fop) then
                # Opposite operator: can distribute
                # result = NodeNary.make(dop)
                # node.each do |child|
                #     result << NodeNary.make(dop,child,self).flatten
                # end
                # return result.flatten
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
            # print "NODE to_sum_product with tree=#{self}\n"
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

        ## Tells if +self+ includes +tree+.
        def include?(tree)
            # By default: equality comparison.
            return self == tree
        end

        ## Tells if +self+ covers +tree+
        def cover?(tree)
            # By default: equality comparison.
            return self == tree
        end
    end

    
    ## 
    # Represents a value node.
    class NodeValue < Node

        protected

        ## Creates a node by +value+.
        def initialize(value) # :nodoc:
            @value = value
            # @sym = @value.to_s.to_sym
            @sym = nil
        end

        public

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def get_variablesRecurse() # :nodoc:
            return [ ]
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(NodeValue)
            return self.eval() == node.eval()
        end

        # Node::include? is now enough.
        # ## Tells if the +self+ includes +tree+.
        # def include?(tree)
        #     return ( tree.is_a?(NodeValue) and self.eval() == tree.eval() )
        # end

        ## Computes the value of the node.
        def eval
            return @value
        end

        ## Gets the operator.
        def op
            return @value.to_s.to_sym
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            @sym = @value.to_s.to_sym unless @sym
            return @sym
        end

        ## Converts to a string.
        def to_s # :nodoc:
            return @value ? "1" : "0"
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
            # @sym = @variable.to_s.to_sym
            @sym = nil
        end

        ## Gets the operator.
        #
        #  Default: +nil+ (none).
        def op
            :variable
        end

        # Node::include? is now enough. 
        # ## Tells if the +self+ includes +tree+.
        # def include?(tree)
        #     return ( tree.is_a?(NodeVar) and self.variable == tree.variable )
        # end

        ## Computes the value of the node.
        def eval()
            return @variable.value
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            @sym = @variable.to_s.to_sym unless @sym
            return @sym
        end

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def get_variablesRecurse() # :nodoc:
            return [ @variable ]
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(NodeVar)
            return self.variable == node.variable
        end

        ## Converts to a string.
        def to_s # :nodoc:
            result = variable.to_s
            # Variables using more than one character are parenthesized
            # to avoid confunsion with the AND operator.
            result = "{" + result + "}" if (result.size > 1)
            return result
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
            # @sym = self.to_s.to_sym
            @sym = nil
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

        ## Tells if the node is a parent.
        def is_parent?
            return true
        end

        # Also acts as an array of nodes
        def_delegators :@children, :[], :empty?, :size

        ## Adds a +child+.
        def add(child)
            unless child.is_a?(Node) then
                raise ArgumentError.new("Not a valid class for a child: "+
                                        "#{child.class}")
            end
            @children << child
        end

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
            @sym = self.to_s.to_sym unless @sym
            return @sym
        end

        ## Gets the variables, recursively, without postprocessing.
        #
        #  Returns the variables into sets of arrays with possible doublon
        def get_variablesRecurse() # :nodoc:
            return @children.reduce([]) do |res,child|
                res.concat(child.get_variablesRecurse)
            end
        end

        ## Compares with +node+.
        def ==(node) # :nodoc:
            return false unless node.is_a?(Node)
            return false unless self.op == node.op
            return false unless self.size == node.size
            # There is no find_with_index!
            # return ! @children.find_with_index {|child,i| child != node[i] }
            @children.each_with_index do |child,i|
                return false if child != node[i]
            end
            return true
        end

        ## Tells if +self+ includes +tree+.
        #
        #  NOTE: * This is a tree inclusion, not a logical inclusion.
        #        * It is assumed that the trees are sorted.
        def include?(tree)
            # Check from current node.
            if self.op == tree.op and self.size >= tree.size then
                return true unless tree.each.with_index.find do |child,i|
                    child != @children[i]
                end
            end
            # Check each child.
            @children.each do |child|
                return true if child.include?(tree)
            end
            # Do not include.
            return false
        end

        ## Tells if +self+ covers +tree+.
        #
        #  NOTE: * It is assumed that the trees are sorted.
        #        * There might still be cover even when the result is false.
        #          For exact cover checking, please use the LogicTools::Cover
        #          class.
        def cover?(tree)
            # Different operators, no probable cover.
            return false if self.op != tree.op
            # Check for equality with one child.
            return true unless tree.each.with_index.find do |child,i|
                child != @children[i]
            end
            # Check each child.
            @children.each do |child|
                return true if ( child.op == self.op and child.cover?(tree) )
            end
            # Do not include.
            return false
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
            # print "reducing #{self}\n"
            # The operator used for the factors
            fop = @op == :and ? :or : :and
            # Gather the terms to sorted nodes
            terms = @children.map do |child|
                child.op == fop ? child.sort : child
            end
            nchildren = []
            # Keep only the terms that do not contain another one
            # TODO: this loop could be faster I think...
            terms.each_with_index do |term0,i|
                skipped = false
                terms.each_with_index do |term1,j|
                    next if (term0 == term1) # Same term, duplicates will be
                                             # removed after
                    # Checks the X~X or X+~X cases.
                    if ( term0.op == :not and term0.child == term1 ) or
                       ( term1.op == :not and term1.child == term0 ) then
                        # Reduceable to 0 or 1
                        return self.op == :and ? NodeFalse.new : NodeTrue.new
                    end
                    # Checks the covering.
                    next if (term0.op != term1.op) # Different operators
                    # if (term0.include?(term1) and term0 != term1) then
                    #     # term0 contains term1 but is different, skip it
                    #     skipped = true
                    #     break
                    # end
                    if term0.op == :and and term1.cover?(term0) then
                        # print "#{term1} is covering #{term0}\n"
                        # term1 covers term0 skip term0 for AND.
                        skipped = true
                        # break
                    elsif term0.op == :or and term0.cover?(term1) then
                        # print "#{term0} is covering #{term1}\n"
                        # term0 covers term1 skip term0 for OR.
                        skipped = true
                        # break
                    end
                end
                nchildren << term0 unless skipped # Term has not been skipped
            end
            # Avoid duplicates
            nchildren.uniq!
            # print "reduced nchildren=#{nchildren}\n"
            # Generate the result
            if (nchildren.size == 1)
                return nchildren[0]
            else
                return NodeNary.make(@op,*nchildren)
            end
        end

        ## Flatten ands, ors and nots.
        def flatten # :nodoc:
            # print "flatten with #{self}\n"
            res = NodeNary.make(@op,*(@children.reduce([]) do |nchildren,child|
                if (child.op == self.op) then
                    # nchildren.push(*child)
                    nchildren.push(*child.each)
                else
                    nchildren << child
                end
            end)).reduce
            # print "result #{res}\n"
            return res
        end

        ## Creates a new tree where all the *and*, *or* and *not* operators 
        #  from the current node are flattened.
        #
        #  Default: simply duplicate.
        def flatten_deep # :nodoc:
            return NodeNary.make(@op,*(@children.reduce([]) do |nchildren,child|
                child = child.flatten_deep
                if (child.op == self.op) then
                    # nchildren.push(*child)
                    nchildren.push(*child.each)
                else
                    nchildren << child
                end
            end)).reduce
        end

        ## Creates a new tree where the current node is distributed over +node+
        #  according to the +dop+ operator.
        def distribute(dop,node) # :nodoc:
            # print "distribute with self=#{self} and node=#{node}\n"
            fop = dop == :and ? :or : :and
            # print "dop=#{dop} fop=#{fop} self.op=#{@op}\n"
            if (@op == dop) then
                # Self operator is dop: merge node in self
                return NodeNary.make(dop,*self,node).flatten
            else
                # self operator if fop
                if (node.op == fop) then
                    # print "(a+b)(c+d) case\n"
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
                    # print "(a+b)c case\n"
                    # node operator is not fop: (a+b)c or ab+c case
                    nchildren = self.map do |child|
                        NodeNary.make(dop,child,node).flatten
                    end
                    # print "nchildren=#{nchildren}\n"
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
        def clone # :nodoc:
            return NodeAnd.new(*@children.map(&:clone))
        end

        ## Computes the value of the node.
        def eval()
            return !@children.any? {|child| child.eval() == false }
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false) # :nodoc:
            # print "AND to_sum_product with tree=#{self}\n"
            # Flatten if required
            node = flattened ? self : self.flatten_deep
            return node unless node.is_parent?
            # Convert each child to sum of product
            nchildren = node.map do |child|
                # print "recurse to_sum_product for child=#{child}\n"
                # res = child.to_sum_product(true)
                # print "child=#{child} -> res=#{res}\n"
                # res
                child.to_sum_product(true)
            end
            # Distribute
            while(nchildren.size>1)
                # print "nchildren=#{nchildren}\n"
                dist = []
                nchildren.each_slice(2) do |left,right|
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
            # print "result=#{nchildren}\n"
            # # Generate the or
            # if (nchildren.size > 1)
            #     return NodeOr.new(*nchildren)
            # else
            #     return nchildren[0]
            # end
            return nchildren[0].flatten
        end

        ## Converts to a string.
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
        def clone # :nodoc:
            return NodeOr.new(*@children.map(&:clone))
        end

        ## Computes the value of the node.
        def eval
            return @children.any? {|child| child.eval() == true }
        end

        ## Creates a sum fo product from the tree rooted by current node.
        #
        #  Argument +flattened+ tells if the tree is already flattend
        def to_sum_product(flattened = false) # :nodoc:
            # print "OR to_sum_product with tree=#{self}\n"
            return NodeOr.new(
                *@children.map {|child| child.to_sum_product(flattened) } ).flatten
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
            # @sym = self.to_s.to_sym
            @sym = nil
        end

        ## Tells if the node is a parent.
        def is_parent?
            return true
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
        def get_variablesRecurse() # :nodoc:
            return @child.get_variablesRecurse
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
            return false unless self.op == node.op
            return self.child == node.child
        end

        ## Tells if the +self+ includes +tree+.
        def include?(tree)
            return true if self == tree # Same tree, so inclusion.
            # Check the child
            return true if @child.include?(tree)
            # Do not include
            return false
        end

        ## Converts to a symbol.
        def to_sym # :nodoc:
            @sym = self.to_s.to_sym unless @sym
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
        def clone # :nodoc:
            return NodeNot.new(@child.clone)
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
            # print "NOT to_sum_product with tree=#{self}\n"
            # return NodeNot.new(@child.to_sum_product(flatten))
            # Flatten deeply if required.
            nnode = flattened ? self : self.flatten_deep
            if (nnode.op != :not) then
                # Not a NOT any longer.
                return nnode.to_sum_product
            end
            # Still a NOT, so apply De Morgan's law.
            child = nnode.child
            if child.op == :or then
                # Can apply De Morgan's law for OR.
                return NodeAnd.new( *child.each.map do |n|
                    NodeNot.new(n).to_sum_product
                end ).to_sum_product
            elsif child.op == :and then
                # Can apply De Morgan's law for AND.
                return NodeOr.new( *child.each.map do |n|
                    NodeNot.new(n).to_sum_product
                end )
            else
                # Nothing to do more.
                return nnode
            end
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
