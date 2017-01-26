######################################################################
#  Sets of tools for converting logic representations to one another #
######################################################################

# AND-OR-NOT tree representation.
require "logic_tools/logictree.rb"

# Cover representation.
require "logic_tools/logiccover.rb"

# TODO: bdd representation.

module LogicTools

    class Node
        ## Converts to a cover of a boolean space based of +variables+.
        #  
        #  NOTE: the variables of the space are also extracted from +self+.
        def to_cover(*variables)
            # Check the cases of trivial trees.
            if self.is_a?(NodeTrue) then
                if variables.empty? then
                    cover = Cover.new("all")
                    cover << Cube.new("-")
                else
                    cover = Cover.new(*variables)
                    cover << Cube.new("-"*variables.size)
                end
                return cover
            elsif self.is_a?(NodeFalse) then
                return Cover.new(*variables)
            end

            # Get the variables for converting them to indexes in the cubes
            vars = (variables + self.get_variables.map(&:to_s)).uniq
            # print "vars=#{vars}\n"
            # Converts the tree rooted by self to a sum of products
            # (reduced to limit the number of cubes and their sizes).
            tree = self.to_sum_product.flatten.reduce
            # print "tree=#{tree}\n"
            
            # Create an empty cover.
            cover = Cover.new(*vars)

            # Treat the trival cases.
            case tree.op 
            when :true then
                # Logic true
                cover << Cube.new("-" * cover.width)
                return cover
            when :false then
                # Logic false
                return cover
            when :variable then
                # Single variable
                str = "-" * cover.width
                index = vars.index(tree.variable.to_s)
                str[index] = "1"
                cover << Cube.new(str)
                return cover
            when :not then
                # Single complement of a variable
                str = "-" * cover.width
                index = vars.index(tree.child.variable.to_s)
                str[index] = "0"
                cover << Cube.new(str)
                return cover
            end

            # Treat the other cases.

            # Ensure we have a sum of product structure.
            tree = [ tree ] unless tree.op == :or

            # print "tree=#{tree}\n"

            # Fill it with the cubes corresponding to each product
            tree.each do |product|
                product = [ product ] unless product.is_a?(NodeNary)
                # print "product=#{product}\n"
                # Generate the bit string of the cube
                str = "-"*vars.size
                product.each do |lit|
                    if lit.is_a?(NodeNot) then
                        index = vars.index(lit.child.variable.to_s)
                        # The litteral is a not
                        if str[index] == "1" then
                            # But it was "1" previously, contradictory cube:
                            # mark it for removal
                            str = nil
                            break
                        else
                            # No contradiction, put a "0"
                            str[index] = "0"
                        end
                    else
                        # print "lit=#{lit}\n"
                        index = vars.index(lit.variable.to_s)
                        # The litteral is a variable
                        if str[index] == "0" then
                            # But it was "0" previously, contradictory cube:
                            # mark it for removal.
                            str = nil
                            break
                        else
                            # No contradiction, put a "1"
                            str[index] = "1"
                        end
                    end
                end
                # Create and add the corresponding cube if any.
                cover.add(Cube.new(str)) if str
            end
            # print "cover=#{cover}\n"
            # Remove the duplicate cubes if any.
            cover.uniq!
            # Return the resulting cover.
            return cover
        end
    end

    class Cover
        ## Coverts to an AND-OR-NOT tree.
        def to_tree()
            # Generate the variable index.
            vars = self.each_variable.to_a

            # Treat the trivial cases.
            if vars.empty? then
                return self.empty? ? NodeFalse.new : NodeTrue.new
            end
            return NodeFalse.new if self.empty?

            # Treat the other cases.

            # Generate the products.
            prods = self.each_cube.map do |cube|
                # Generate the litterals of the and
                litterals = []
                cube.each.with_index do |val,i|
                    if val == "0" then
                        # "0" bits are converted to not litteral.
                        litterals << NodeNot.new(NodeVar.new(vars[i]))
                    elsif val == "1" then
                        # "1" bits are converted to variable litteral
                        litterals << NodeVar.new(vars[i])
                    end
                end
                # Create and and with the generated litterals.
                NodeAnd.new(*litterals)
            end
            # Is there an empty and?
            if prods.find { |node| node.empty? } then
                # Yes, this is a tautology.
                return NodeTrue.new
            else
                # No, generate the sum and return it.
                return NodeOr.new(*prods)
            end
        end
    end
end
