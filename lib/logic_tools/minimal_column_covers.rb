#########################################################################
# Algorithm for computing the minimal column covers of a boolean matrix #
#########################################################################

module LogicTools


    # ## Computes the minimal column covers of a boolean +matrix+.
    # #
    # #  If +smallest+ is set to one, the method returns the smallest minimal
    # #  column cover instead.
    # #
    # #  The +matrix+ is assumed to be an array of string, each string
    # #  representing a boolean row ("0" for false and "1" for true).
    # def minimal_column_covers(matrix,smallest = false)
    #     # Generate the Petrick's product
    #     product = []
    #     matrix.each do |row|
    #         term = []
    #         # Get the columns covering the row.
    #         row.each_char.with_index do |bit,i|
    #             term << i if bit == "1"
    #         end
    #         product << term
    #     end

    #     # Convert the product to sum of product.
    #     sum = []
    #     product.size.times do |i|
    #         term = []
    #         product[i].size.times do |j|

    #         end
    #     end

    #     if sum.empty?
    #         # No minimal cover
    #         if smallest then
    #             return nil
    #         else
    #             return []
    #         end
    #     end
    #     # Each term of the sum is a minimal cover.
    #     if smallest then
    #         return sum.reduce(sum[0]) do |sum,term|
    #             term.size < sum.size ? term : sum
    #         end
    #     else
    #         return sum
    #     end
    # end


    ## Computes the minimal column covers of a boolean +matrix+.
    #
    #  If +smallest+ is set to one, the method returns the smallest minimal
    #  column cover instead.
    #
    #  The +matrix+ is assumed to be an array of string, each string
    #  representing a boolean row ("0" for false and "1" for true).
    def minimal_column_covers(matrix,smallest = false)
        # Generate a variables nodes for each column: their name is
        # directly the column number.
        variables = matrix[0].size.times.map {|i| Variable.get("#{i}") }
        # Generate the Petrick's product
        product = []
        matrix.each do |row|
            term = []
            # Get the columns covering the row.
            row.each_char.with_index do |bit,i|
                term << NodeVar.new(variables[i]) if bit == "1"
            end
            if term.size == 1 then
                product << term[0]
            elsif term.size > 1 then
                product << NodeOr.new(*term)
            end
        end
        if (product.size == 1)
            product = product[0]
        else
            product = NodeAnd.new(*product)
        end
        # Convert the product to sum of product.
        # print "product=#{product}\n"
        sum = product.sort.reduce.to_sum_product(true).sort.reduce
        # print "sum=#{sum}\n"
        unless sum
            # No minimal cover
            if smallest then
                return nil
            else
                return []
            end
        end
        sum = [ sum ] unless sum.is_a?(NodeOr) # In case sum is not a sum
        # Each term of the sum is a minimal cover.
        result = []
        smallest_cover = nil
        sum.each do |term|
            # Maybe the term is a litteral, if yes, make it an array
            term = [ term ] unless term.is_a?(NodeNary)
            # The name of a variable is directly the column number!
            cover = term.each.map do |lit|
                lit.variable.to_s.to_i
            end
            result << cover
            # In case we look for the smallest
            if smallest then
                if smallest_cover == nil then
                    smallest_cover = cover
                elsif cover.size < smallest_cover.size
                    smallest_cover = cover
                end
            end
        end
        if smallest then
            return smallest_cover
        else
            return result
        end
    end


end
