require 'logger.rb'


module LogicTools

    module Traces

        # Add traces support to the logic tools.


        ## The logger used for displaying the traces.
        TRACES = Logger.new(STDOUT)

        # Format the traces
        TRACES.formatter = proc do |severity, datetime, progname, msg|
              "[#{severity}] #{datetime}: #{msg}\n"
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

    end

end
