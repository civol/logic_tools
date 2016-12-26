######################################################################
#  Sets of tools for converting logic representations to one another #
######################################################################

# AND-OR-NOT tree representation.
require "logic_tools/logictree.rb"

# Cover representation.
require "logic_tools/logiccover.rb"

# TODO: bdd representation.

module LogicTool

    class Node
        ## Converts to a cover.
        def to_cover()
            # Get the variables for converting them to indexes in the cubes
            vars = self.get_variables
            # Converts the tree rooted by self to a sum of products
            tree = self.to_sum_product
            # Create an empty cover.
            cover = Cover.new(vars)
            # Fill it with the cubes corresponding to each product
            tree.each do |product|
                # Generate the bit string of the cube
                str = "-"*vars.size
                product.each {|var| str[vars.index(var)] = var.value }
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
            vars = self.each_variables.to_a
            # Generate the products.
            prods = self.each_cube.map do |cube|
                NodeAnd.new( * cube.each.with_index.map do |val,i|
                    # Each bit to the cube is converted to a litteral.
                    node = NodeVar.new(vars[i])
                    # If the bit is 0, the coresponding variable is to negate.
                    val == 0 ? NodeNot.new(node) : node
                end )
            end
            # Generate the sum and return it.
            return NodeOr.new(*prods)
        end
    end
end
