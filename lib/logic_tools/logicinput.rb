#########################################################################
#           Common command line interface for all Logic Tools           #
#########################################################################


module LogicTools
    ## Displays the short help
    def help_short
        name = File.basename($0)
        puts "Usage: #{name} <\"logic expression\">"
        puts "   or: #{name} -f <file name>"
    end

    ## Get an iterator over the input expression
    #  (either through options or a file).
    def each_input
        # No block? Return an enumerator
        return enum_for(:each_input) unless block_given?
        # A block? Interrate with it
        # Process the arguments
        if ($*.empty?) then
            # No arguments, shows the help and end.
            help_short
            exit(1)
        end
        if $*[0] == "-f" or $*[0] == "--file" then
            # Work from a file, iterate on each line
            exprs = File.read($*[1])
            exprs.gsub!(/\r\n?/, "\n")
            exprs.each_line do |line|
                yield(line)
            end
        elsif $*[0] == "-h" or $*[0] == "--help" then
            help_short
        else
            # Work directly on the arguments as an expression
            yield($*.join)
        end
    end
end
