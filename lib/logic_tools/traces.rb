require 'logger.rb'


module LogicTools

    ## Small class for indenting
    class Indenter
        ## Creates a new indenter.
        def initialize
            @indent = 0
        end

        ## Increase the indent level by +value+.
        #
        #  NOTE:
        #  * the indent level cannot be bellow 0.
        #  * the value can be negative.
        def inc(value = 1)
            @indent += value.to_i
            @indent = 0 if @indent < 0
        end

        ## Decreases the indent level by +value+.
        #
        #  NOTE: 
        #  * the indent level cannot be bellow 0.
        #  * the value can be negative.
        def dec(value = 1)
            @indent -= value.to_i
            @indent = 0 if @indent < 0
        end

        ## Converts to a string (generates the indent.)
        def to_s
            return " " * @indent
        end
    end


    module Traces

        # Add traces support to the logic tools.


        ## The logger used for displaying the traces.
        TRACES = Logger.new(STDOUT)

        ## The indent for the traces.
        TRACES_INDENT = Indenter.new

        # Format the traces
        TRACES.formatter = proc do |severity, datetime, progname, msg|
              "[#{severity}] #{datetime}: #{TRACES_INDENT.to_s}#{msg}\n"
        end
        TRACES.datetime_format = '%H:%M:%S'

        # By default the trace level is set warn.
        TRACES.level = Logger::WARN


        ## Sets the trace level to error.
        def traces_error
            TRACES.level = Logger::ERROR
        end

        ## Sets the trace level to warn.
        def traces_warn
            TRACES.level = Logger::WARN
        end

        ## Sets the trace level to info.
        def traces_info
            TRACES.level = Logger::INFO
        end

        ## Sets the trace level to debug
        def traces_debug
            TRACES.level = Logger::DEBUG
        end


        ## Sends an error-level trace.
        def error(&blk)
            TRACES.error(&blk)
        end

        ## Sends a warn-level trace.
        def warn(&blk)
            TRACES.warn(&blk)
        end

        ## Sends an info-level trace.
        def info(&blk)
            TRACES.info(&blk)
        end

        ## Sends a debug-level trace.
        def debug(&blk)
            TRACES.debug(&blk)
        end


        ## Increases the indent level by +value+.
        def inc_indent(value = 1)
            TRACES_INDENT.inc(value)
        end

        ## Deacreases the indent level by +value+.
        def dec_indent(value = 1)
            TRACES_INDENT.dec(value)
        end


    end

end
