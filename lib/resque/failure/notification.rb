module Resque
  module Failure
    class Notification
      # Generate the text to be displayed in the Slack Notification
      #
      # failure: resque failure
      # level: notification style
      def self.generate(failure, level)
        new(failure, level).generate
      end

      def initialize(failure, level)
        @failure = failure
        @level   = level
      end

      def generate
        send(@level)
      end

      protected

      # Returns the worker & queue linked to the failed job
      #
      def msg_worker
        "`#{@failure.worker}` failed processing `#{@failure.queue}`"
      end

      # Returns the formatted payload linked to the failed job
      #
      def msg_payload
        payload = @failure.payload.inspect.split('\n') if @failure&.payload&.inspect
        "Payload:\n```#{format_message(payload)}```"
        # TODO: in theory this could be very large as well, but we'll ignore that for now
      end

      # Returns the formatted exception linked to the failed job
      #
      def msg_exception
        "Exception:\n`#{@failure.exception}`"
      end

      # Returns the formatted exception backtrace
      #
      def msg_backtrace
        format_message(@failure.exception&.backtrace)
      end

      # Returns the verbose text notification
      # NOTE: the exception backtrace may be split into multiple blocks
      #
      def verbose
        str = msg_backtrace
        arr = []
        wrap = '```'

        # Split the object into groups no larger than MAX_CHARS each
        # 3500 is well below the slack auto-split threshold
        max_chars = 3500
        until str.size <= max_chars do
          arr << wrap + str.slice!(0, str.rindex("\n", max_chars)) + wrap
          str.delete_prefix!("\n") # get rid of any leading newlines
        end
        arr << wrap + str + wrap  unless  str.empty?

        # prepend the general info
        arr[0] = "#{msg_worker}\n#{msg_payload}\n#{msg_exception}\n" + arr[0]

        return arr
      end

      # Returns the compact text notification
      #
      def compact
        ["#{msg_worker}\n#{msg_payload}\n#{msg_exception}"]
      end

      # Returns the minimal text notification
      #
      def minimal
        ["#{msg_worker}\n#{msg_payload}"]
      end

      def format_message(obj)
        return '' unless obj
        obj.map{ |l| "\t" + l }.join("\n")
      end

    end
  end
end
