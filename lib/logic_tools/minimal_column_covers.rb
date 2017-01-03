#########################################################################
# Algorithm for computing the minimal column covers of a boolean matrix #
#########################################################################

module LogicTools

    ## Converts a +product+ of sum to a sum of product.
    #
    #  NOTE: * Both the input are outputs are represented as array of arrays.
    def to_sum_product_array(product)
        return product[0].map {|term| [term] } if product.size == 1
        # Generate the first term.
        sum = product[0].product(product[1]) 
        # print "sum = #{sum}, product=#{product}\n"
        (2..(product.size-1)).each do |i|
            sum.map! do |term|
                # print "mapping #{product[i]}\n"
                product[i].map do |fact| 
                    term.clone << fact
                    term.uniq!
                    term
                end
            end
            # print "then sum=#{sum}\n"
            sum.flatten!(1)
            # sum.each { |term| term.uniq! }
            sum.uniq!
            # print "now sum=#{sum}\n"
        end
        return sum
    end

    ## Computes the minimal column covers of a boolean +matrix+.
    #
    #  If +smallest+ is set to one, the method returns the smallest minimal
    #  column cover instead.
    #
    #  The +matrix+ is assumed to be an array of string, each string
    #  representing a boolean row ("0" for false and "1" for true).
    def minimal_column_covers(matrix,smallest = false)
        # print "matrix=#{matrix}\n"

        # Step 1: reduce the matrix for faster processing.
        # First put appart the essential columns.
        essentials = []
        matrix.each do |row|
            col = nil
            row.each_char.with_index do |c,i|
                if c == "1" then
                    if col then
                        # The row has several "1", no essential column there.
                        col = nil
                        break
                    end
                    col = i
                end
            end
            # An essential column is found.
            essentials << col if col
        end
        essentials.uniq!
        # print "essentials = #{essentials}\n"
        # The remove the rows covered by essential columns.
        keep = [ true ] * matrix.size
        essentials.each do |col|
            matrix.each.with_index do |row,i|
                keep[i] = false if row[col] == "1"
            end
        end
        # print "keep = #{keep}\n"
        reduced = matrix.select.with_index {|row,i| keep[i] }
        # print "matrix = #{matrix}\n"
        # print "reduced = #{reduced}\n"
        if reduced.empty? then
            # Essentials columns are enough for the cover, end here.
            if smallest then
                return essentials
            else
                return [ essentials ]
            end
        end
        # Then remove the dominating rows
        # For that purpose, sort them lexicographically.
        # print "reduced=#{reduced}\n"
        reduced.sort!.reverse!
        reduced = reduced.select.with_index do |row,i|
            i == reduced.size-1 or row.each_char.with_index.find do |c,j|
                ( c == "0" ) and ( (i+1)..(reduced.size-1) ).each.find do |k|
                    reduced[k][j] == "1"
                end
            end
        end
        # print "now reduced=#{reduced}\n"

        # Step 2: Generate the Petrick's product.
        product = []
        reduced.each do |row|
            term = []
            # Get the columns covering the row.
            row.each_char.with_index do |bit,i|
                term << i if bit == "1"
            end
            product << term unless term.empty?
        end
        # print "product=#{product}\n"
        if (product.empty?) then
            sum = product
        else
            product.sort!.uniq!
            sum = to_sum_product_array(product)
            # print "sum=#{sum}\n"
            sum.sort!.uniq!
        end

        # Add the essentials to the result and return it.
        if smallest then
            # print "smallest_cover=#{smallest_cover}, essentials=#{essentials}\n"
            return essentials if sum.empty?
            # Look for the smallest cover
            sum.sort_by! { |cover| cover.size }
            if essentials then
                return sum[0] + essentials
            else
                return sum[0]
            end
        else
            sum.map! { |cover| cover + essentials }
            return sum
        end
    end



    # ## Computes the minimal column covers of a boolean +matrix+.
    # #
    # #  If +smallest+ is set to one, the method returns the smallest minimal
    # #  column cover instead.
    # #
    # #  The +matrix+ is assumed to be an array of string, each string
    # #  representing a boolean row ("0" for false and "1" for true).
    # def minimal_column_covers2(matrix,smallest = false)
    #     # print "matrix=#{matrix}\n"
    #     # Generate a variables nodes for each column: their name is
    #     # directly the column number.
    #     variables = matrix[0].size.times.map {|i| Variable.get("#{i}") }

    #     # Step 1: reduce the matrix for faster processing.
    #     # First put appart the essential columns.
    #     essentials = []
    #     matrix.each do |row|
    #         col = nil
    #         row.each_char.with_index do |c,i|
    #             if c == "1" then
    #                 if col then
    #                     # The row has several "1", no essential column there.
    #                     col = nil
    #                     break
    #                 end
    #                 col = i
    #             end
    #         end
    #         # An essential column is found.
    #         essentials << col if col
    #     end
    #     essentials.uniq!
    #     # print "essentials = #{essentials}\n"
    #     # The remove the rows covered by essential columns.
    #     keep = [ true ] * matrix.size
    #     essentials.each do |col|
    #         matrix.each.with_index do |row,i|
    #             keep[i] = false if row[col] == "1"
    #         end
    #     end
    #     # print "keep = #{keep}\n"
    #     reduced = matrix.select.with_index {|row,i| keep[i] }
    #     # print "matrix = #{matrix}\n"
    #     # print "reduced = #{reduced}\n"
    #     if reduced.empty? then
    #         # Essentials columns are enough for the cover, end here.
    #         if smallest then
    #             return essentials
    #         else
    #             return [ essentials ]
    #         end
    #     end
    #     # Then remove the dominating rows
    #     # For that purpose, sort them lexicographically.
    #     # print "reduced=#{reduced}\n"
    #     reduced.sort!.reverse!
    #     reduced = reduced.select.with_index do |row,i|
    #         i == reduced.size-1 or row.each_char.with_index.find do |c,j|
    #             ( c == "0" ) and ( (i+1)..(reduced.size-1) ).each.find do |k|
    #                 reduced[k][j] == "1"
    #             end
    #         end
    #     end
    #     # print "now reduced=#{reduced}\n"

    #     # Step 2: Generate the Petrick's product.
    #     product = []
    #     reduced.each do |row|
    #         term = []
    #         # Get the columns covering the row.
    #         row.each_char.with_index do |bit,i|
    #             term << NodeVar.new(variables[i]) if bit == "1"
    #         end
    #         if term.size == 1 then
    #             product << term[0]
    #         elsif term.size > 1 then
    #             product << NodeOr.new(*term)
    #         end
    #     end
    #     # print "product=#{product}\n"
    #     if (product.empty?) then
    #         sum = nil
    #     elsif (product.size == 1)
    #         sum = product[0]
    #     else
    #         product = NodeAnd.new(*product)
    #         sum = product.sort.reduce.to_sum_product(true).sort.reduce
    #     end

    #     # Step 3: Convert the product to sum of product.
    #     # print "sum=#{sum}\n"
    #     unless sum
    #         # No minimal cover
    #         if smallest then
    #             return nil
    #         else
    #             return []
    #         end
    #     end
    #     sum = [ sum ] unless sum.is_a?(NodeOr) # In case sum is not a sum

    #     # Step4: Each term of the sum is a minimal cover.
    #     result = []
    #     smallest_cover = nil
    #     sum.each do |term|
    #         # Maybe the term is a litteral, if yes, make it an array
    #         term = [ term ] unless term.is_a?(NodeNary)
    #         # The name of a variable is directly the column number!
    #         cover = term.each.map do |lit|
    #             lit.variable.to_s.to_i
    #         end
    #         result << cover
    #         # In case we look for the smallest
    #         if smallest then
    #             if smallest_cover == nil then
    #                 smallest_cover = cover
    #             elsif cover.size < smallest_cover.size
    #                 smallest_cover = cover
    #             end
    #         end
    #     end
    #     # Add the essentials to the result and return it.
    #     if smallest then
    #         # print "smallest_cover=#{smallest_cover}, essentials=#{essentials}\n"
    #         return essentials unless smallest_cover
    #         return smallest_cover unless essentials
    #         return smallest_cover + essentials
    #     else
    #         result.map! { |cover| cover + essentials }
    #         return result
    #     end
    # end


end
