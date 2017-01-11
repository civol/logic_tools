#########################################################################
# Algorithm for computing the minimal column covers of a boolean matrix #
#########################################################################

# require 'set'
require 'timeout'

module LogicTools

    ## Converts a +product+ of sum to a sum of product.
    #
    #  NOTE: * Both the input are outputs are represented as array of arrays.
    def to_sum_product_array(product)
        return product[0].map {|term| [term] } if product.size == 1
        # Generate the initial terms.
        sum = product[0].product(product[1]) 
        sum.each {|term| term.sort!.uniq! }
        sum.uniq!
        # Fill then with each factor to the resulting sum of product.
        # print "sum = #{sum}, product=#{product}\n"
        (2..(product.size-1)).each do |i|
            sum.map! do |term|
                # # print "mapping #{product[i]}\n"
                set = []
                product[i].each do |fact|
                    if term.include?(fact) then
                        set << term unless set.include?(term)
                    else
                        nterm = term.clone
                        nterm << fact
                        nterm.sort!
                        set << nterm
                    end
                end
                set
            end
            sum.flatten!(1)
            # print "then sum=#{sum}\n"
            sum.uniq!
            # print "now sum=#{sum}\n"
            # pid, size = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{$$}"`.strip.split.map(&:to_i)
            # print "memory usage=#{size}\n"
        end
        # print "\n"
        return sum
    end


    ## Class for storing and counting occurences of objects.
    class HashCounter < Hash

        ## Creates a new hash counter.
        def initialize
            self.default = 0
        end

        ## Increments the number of +element+.
        def inc(element)
            self[elem] += 1
        end

        ## Decrements the number of +element+.
        def dec(element)
            if (self[elem] -= 1) == 0 then
                # No more instance of the element, remove the entry.
                self.delete(elem)
            end
        end
    end


    ## Class for applying branch and bound for extracting from a product of sums
    #  the smallest term of the corresponding sum of products.
    #
    #  Attributes:
    #  +product+::   the product to extract the term from.
    #  +cur_term+::  the current term.
    #  +best_term+:: the best term found.
    #  +best_cost+:: the best cost.
    #  +deadline+::  time before returning the current best solution.
    #  +time+::      initial time.
    class SmallestSumTerm

        ## Creates the solver for a product.
        def initialize(product, deadline = Float::INFINITY)
            @product = product
            @cur_term = []
            # @cur_term = HashCounter.new
            @best_term = nil
            @best_cost = @cur_cost = Float::INFINITY
            @deadline = deadline
        end

        ## Selects a +term+ for solution.
        def make_best(term)
            # print "make_best\n"
            @best_term = term.uniq
            @best_cost = @best_term.size
        end

        ## Bounds a partial +term+.
        #  
        #  # NOTE: may modify term through uniq! (for performance purpose.)
        #  NOTE: It is assumed that term is hash-like
        def bound(term)
            # if Time.now - @time >= @deadline and 
            #    @best_cost < Float::INFINITY then
            #     # Time over, force a high cost.
            #     return Float::INFINITY
            # end
            if (term.size >= @best_cost) then
                return term.uniq.size
            else
                return term.size
            end
            # return term.size
        end

        ## Solves the problem using branch and bound.
        def solve()
            # Solve the problem throughly.
            begin
                Timeout::timeout(@deadline) {
                    self.branch(0)
                }
            rescue Timeout::Error
                # Time out, is there a solution?
                # print "Timeout!\n"
                unless @best_term
                    # No, quickly create one including the first element
                    # of each factor.
                    @best_term = @product.map {|fact| fact[0] }
                    @best_term.uniq!
                end
            end
            return @best_term
        end

        ## Branch in the branch and bound algorithm.
        def branch(pi)
            # # Start the timer if required.
            # @time = Time.now if (pi == 0)
            # # Check the deadline.
            # if Time.now - @time >= @deadline and 
            #    @best_cost < Float::INFINITY then
            #     # Time over, end here.
            #     return @best_term
            # end
            # Bound the current term.
            if (self.bound(@cur_term) < @best_cost)
                # Better bound, can go on with the current solution.
                if pi == @product.size then
                    # But this is the end, so update the best term.
                    make_best(@cur_term)
                else
                    # Still a possible solution, recurse.
                    @product[pi].each do |elem|
                        @cur_term.push(elem)
                        # @cur_term.inc(elem)
                        # solve(pi+1)
                        branch(pi+1)
                        @cur_term.pop
                        # @cur_term.dec(elem)
                    end
                end
            end
            return @best_term
        end
    end


    ## Extracts from a +product+ of sums the smallest term of the corresponding
    #  sum of products.
    #
    #  NOTE: * Both the input are outputs are represented as array of arrays.
    #        * Uses a branch and bound algorithm.
    def smallest_sum_term(product, deadline = Float::INFINITY)
        return [product[0][0]] if product.size == 1
       
        # Create the solver and applies it
        return SmallestSumTerm.new(product,deadline).solve
    end

    ## Computes the minimal column covers of a boolean +matrix+.
    #
    #  If +smallest+ is set to one, the method returns the smallest minimal
    #  column cover instead.
    #
    #  The +matrix+ is assumed to be an array of string, each string
    #  representing a boolean row ("0" for false and "1" for true).
    def minimal_column_covers(matrix, smallest = false, 
                              deadline = Float::INFINITY)
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

        to_optimize = false
        removed_columns = []
        begin
            to_optimize = false
            # Then remove the dominating rows
            reduced.uniq!
            reduced = reduced.select.with_index do |row0,i|
                ! reduced.find.with_index do |row1,j|
                    if i == j then
                        false
                    else
                        # The row is dominating if in includes another row.
                        res = row0.each_char.with_index.find do |c,j|
                            row1[j] == "1" and c == "0"
                        end
                        # Not dominating if res
                        !res
                    end
                end
            end

            # # Finally remove the dominated columns if only one column cover
            # # is required.
            # if smallest and reduced.size >= 1 then
            #     size = reduced[0].size
            #     size.times.reverse_each do |col0|
            #         next if removed_columns.include?(col0)
            #         size.times do |col1|
            #             next if col0 == col1
            #             # The column is dominated if it is included into another.
            #             res = reduced.find do |row|
            #                 row[col0] == "1" and row[col1] == "0"
            #             end
            #             # Not dominated if res
            #             unless res
            #                 to_optimize = true
            #                 # print "removing column=#{col0}\n"
            #                 # Dominated, remove it
            #                 reduced.each { |row| row[col0] = "0" }
            #                 removed_columns << col0
            #             end
            #         end
            #     end
            # end
        end while(to_optimize)

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


        if smallest then
            if product.empty? then
                return essentials
            end
            cover = smallest_sum_term(product,deadline)
            if essentials then
                # print "essentials =#{essentials} cover=#{cover}\n"
                essentials.each {|cube| cover.unshift(cube) }
                return cover
            else
                return cover
            end
        end

        # print "product=#{product}\n"
        if product.empty? then
            sum = product
        else
            product.each {|fact| fact.sort!.uniq! }
            product.sort!.uniq!
            # print "product=#{product}\n"
            sum = to_sum_product_array(product)
            # print "sum=#{sum}\n"
            sum.each {|term| term.uniq! }
            sum.uniq!
            sum.sort_by! {|term| term.size }
            # print "sum=#{sum}\n"
        end

        # # Add the essentials to the result and return it.
        # if smallest then
        #     # print "smallest_cover=#{smallest_cover}, essentials=#{essentials}\n"
        #     return essentials if sum.empty?
        #     # Look for the smallest cover
        #     sum.sort_by! { |cover| cover.size }
        #     if essentials then
        #         return sum[0] + essentials
        #     else
        #         return sum[0]
        #     end
        # else
            sum.map! { |cover| essentials + cover }
            return sum
        # end
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
