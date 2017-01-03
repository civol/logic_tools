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
        ## Converts to a cover.
        def to_cover()
            # Check the cases of trivial trees.
            if self.is_a?(NodeTrue) then
                cover = Cover.new("all")
                cover << Cube.new("-")
                return cover
            elsif self.is_a?(NodeFalse) then
                return Cover.new()
            end

            # Get the variables for converting them to indexes in the cubes
            vars = self.get_variables
            # Converts the tree rooted by self to a sum of products
            # (reduced to limit the number of cubes and their sizes).
            tree = self.to_sum_product.reduce
            # Create an empty cover.
            cover = Cover.new(*vars)
            # Fill it with the cubes corresponding to each product
            tree.each do |product|
                product = [ product ] unless product.is_a?(NodeNary)
                # Generate the bit string of the cube
                str = "-"*vars.size
                product.each do |lit|
                    if lit.is_a?(NodeNot) then
                        # The litteral is a not: put a "0"
                        str[vars.index(lit.child.variable)] = "0"
                    else
                        # The litteral is a variable: put a "1"
                        str[vars.index(lit.variable)] = "1"
                    end
                end
                # Create and add the corresponding cube.
                cover.add(Cube.new(str))
            end
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
            # Generate the sum and return it.
            return NodeOr.new(*prods)
        end
    end
end
