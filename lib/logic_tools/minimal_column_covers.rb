#########################################################################
# Algorithm for computing the minimal column covers of a boolean matrix #
#########################################################################

module LogicTools

    # ## Checks if a list of +columns+ is a boolean matrix cover with +value+.
    # def is_matrix_cover?(columns,matrix,value = "1")
    #     # print "is_matrix_conver? with columns=#{columns} and matrix=#{matrix} for value=#{value}\n"
    #     # Check if we can find a "1" among the colomns in each row.
    #     matrix.each do |row|
    #         unless columns.find {|col| row[col] == value }
    #             # No expected +value+ found, this is not a matrix cover.
    #             return false
    #         end
    #     end
    #     # This is a matrix cover
    #     return true
    # end

    # ## Converts a list of +columns+ to a bit string of +size+ characters.
    # #
    # #  The bits string contains a "1" at each column and "0" at the other
    # #  places.
    # def columns2bitstring(columns,size)
    #     # print "columns2bitstring with columns=#{columns} and size=#{size}\n"
    #     bits = "0" * size
    #     columns.each {|col| bits[col] = "1" }
    #     print "bits=#{bits}\n"
    #     return bits
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
        sum = product.to_sum_product
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


    # ## Computes the minimal column covers of a boolean +matrix+.
    # #
    # #  If +smallest+ is set to one, the method returns the smallest minimal
    # #  column cover instead.
    # #
    # #  The +matrix+ is assumed to be an array of string, each string
    # #  representing a boolean row ("0" for false and "1" for true).
    # def minimal_column_covers(matrix, smallest = false)
    #     print "matrix=#{matrix}\n"
    #     return [] if matrix.empty? # Empty matrix: no cover.
    #     
    #     # Approach: compute the 1-colunm covers, then the 2-column covers
    #     # and so on, removing at each step the covers which include smaller
    #     # covers.
    #     # For that purpose, a cover in processing is represented as an array
    #     # whose elements are the indexes of the included columns whereas
    #     # an already selected cover (with less columns), is represented
    #     # as a bit string where "1" represents the included columns.
    #     # With that approach checking if a n-column cover includes another
    #     # one can be done with at worst n-1 comparisons (the size of the
    #     # largest possible already selected cover).

    #     # Create the table of the selected cover.
    #     selected = []
    #     # Creates the table of the potential covers
    #     potentials = []

    #     # Step 1: find the 1-column covers.
    #     # Get the number of remaining columns.
    #     ncols = matrix[0].length
    #     # Process them.
    #     ncols.times do |col|
    #         if is_matrix_cover?([col],matrix) then
    #             return [col] if smallest # The smallest minimal column cover is found
    #             # A 1-column cover is found: select it.
    #             selected << columns2bitstring([col],ncols)
    #         else
    #             # This column is not a cover, do not select it but add it 
    #             # to the potential covers.
    #             potentials << [ col ]
    #         end
    #     end
    #     print "selected = #{selected}\n"

    #     # Step 2: remove the 0-columns
    #     potentials.delete_if { |col| is_matrix_cover?(col,matrix,"0") }

    #     # Step 3: find the larger column covers.
    #     # Get the number of columns to combine.
    #     ncols = potentials.size
    #     # Process them
    #     (2..ncols).each do |size| # For each size-cover
    #         (1..size).each do |cnt| # Add columns until there are size of them
    #             npotentials = [] # New potential covers
    #             ncols.times do |col| # Try column number col
    #                 potentials.each do |potential|
    #                     next if potential[-1] >= col
    #                     npotential = potential + [ col ]
    #                     # Check if npotential includes a selected cover
    #                     unless npotential.find {|c| selected.find{|s| s[c] == "1" }}
    #                         # No, checks if it is a cover
    #                         if is_matrix_cover?(npotential,matrix) then
    #                             # Yes, select or return it (if looking for smallest)
    #                             return npotential if smallest
    #                             selected << columns2bitstring(npotential,ncols)
    #                         else
    #                             # Not a cover yet, remember it
    #                             npotentials << npotential
    #                         end
    #                     end
    #                 end
    #             end
    #             # Renew the potential covers
    #             potentials = npotentials
    #             print "potentials.size=#{potentials.size}\n"
    #         end
    #     end

    #     # Step 3: return the selected covers as lists of column numbers
    #     return selected.map do |selected|
    #         cover = []
    #         selected.each_char.with_index { |v,col| cover << col if v == "1" }
    #         cover
    #     end
    #     return cover
    # end
end
