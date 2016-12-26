#########################################################################
# Algorithm for computing the minimal column covers of a boolean matrix #
#########################################################################

module LogicTools

    ## Checks if a list of +columns+ is a boolean matrix cover.
    def is_matrix_cover?(columns,matrix)
        # Check if we can find a "1" among the colomns in each row.
        matrix.each do |row|
            unless columns.find {|col| row[col] == "1" }
                # No "1" found, this is not a matrix cover.
                return false
            end
        end
        # This is a matrix cover
        return true
    end

    ## Converts a list of +columns+ to a bit string of +size+ characters.
    #
    #  The bits string contains a "1" at each column and "0" at the other
    #  places.
    def columns2bitstring(columns,size)
        bits = "0" * size
        columns.each {|col| bits[col] = "1" }
        return bits
    end


    ## Computes the minimal column covers of a boolean +matrix+.
    #
    #  The +matrix+ is assumed to be an array of string, each string
    #  representing a boolean row ("0" for false and "1" for true).
    def minimal_column_covers(matrix)
        # Get the number of columns.
        ncols = matrix[0].length
        
        # Approach: compute the 1-colunm covers, then the 2-column covers
        # and so on, removing at each step the covers which include smaller
        # covers.
        # For that purpose, a cover in processing is represented as an array
        # whose elements are the indexes of the included columns whereas
        # an already selected cover (with less columns), is represented
        # as a bit string where "1" represents the included columns.
        # With that approach checking if a n-column cover includes another
        # one can be done with at worst n-1 comparisons (the size of the
        # largest possible already selected cover).

        # Create the table of the selected cover.
        selected = []
        # Creates the table of the potential covers
        potentials = []

        # Step 1: find the 1-column covers.
        ncols.times do |col|
            if is_matrix_cover?([col],matrix) then
                # This column is not a cover, do not select it but add it 
                # to the potential covers.
                potentials << [ col ]
            else
                # A 1-column cover is found: select it.
                selected << columns2bitstring([col],ncols)
            end
        end

        # Step 2: find the larger column covers.
        (2..ncols).each do |size| # For each size-cover
            (1..size).each do |cnt| # Add columns until there are size of them
                npotentials = [] # New potential covers
                ncols.times do |col| # Try column number col
                    potentials.each do |potential|
                        npotential = potential + [ col ]
                        # Check if npotential includes a selected cover
                        unless npotential.find {|c| selected.find{|s| s[p] == "1" }}
                            # No, checks if it is a cover
                            if is_matrix_cover?(npotential,matrix) then
                                # Yes, select it
                                selected << columns2bitstring(npotential,ncols)
                            else
                                # Not a cover yet, remember it
                                npotentials << npotential
                            end
                        end
                    end
                end
                # Renew the potential covers
                potential = npotential
            end
        end

        # Step 3: return the selected covers as lists of column numbers
        return selected.map do |selected|
            cover = []
            selected.each.with_index { |v,col| cover << col }
            cover
        end
    end
end
