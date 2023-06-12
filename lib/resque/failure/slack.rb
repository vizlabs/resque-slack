require 'resque'
require 'slack-ruby-client'
require_relative 'notification.rb'

module Resque
  module Failure
    class Slack < Base
      LEVELS = %i(verbose compact minimal)

      # NOTE: for testing and debugging:
      #   failure      = Resque::Failure::Slack.new(exception[obj], worker[str], queue[str], payload[hash])
      #                  #                          exception, "viz-bg:1234:matt_test", "matt_test", {"class"=>"MattTest", "args"=>{foo: 'bar'}}
      #   failure.report_exception()
      # OR
      #   slack_client = Resque::Failure::Slack.client
      #   chnl         = Resque::Failure::Slack.channel
      #   slack_client.chat_postMessage(channel: chnl, text: "test message", as_user: true)
      #   slack_client.chat_postMessage(channel: chnl, text: "```#{failure.text}```", as_user: true)

      # Refrence:
      #   text         = Resque::Failure::Notification.generate(self, overriden_level)

      class << self
        attr_accessor :channel # Slack channel id.
        attr_accessor :token   # Team token
        attr_accessor :client  # Slack client
        attr_accessor :level_override
        # Notification style:
        #
        # verbose: full backtrace (default)
        # compact: exception only
        # minimal: worker and payload
        attr_accessor :level

        def level
          @level && LEVELS.include?(@level) ? @level : :verbose
        end
      end

      # Configures the failure backend. You will need to set
      # a channel id and a team token.
      #
      # @example Configure your Slack account:
      #   Resque::Failure::Slack.configure do |config|
      #     config.channel = 'CHANNEL_ID'
      #     config.token = 'TOKEN'
      #     config.verbose = true or false, true is the default
      #   end
      def self.configure
        self.level_override = {}
        yield self
        raise 'Slack channel and token are not configured.' unless configured?
        ::Slack.configure do |c|
          c.token = token
        end
        self.client = ::Slack::Web::Client.new
        client.auth_test
        level_override.default = level
      end

      def self.configured?
        !!channel && !!token
      end

      # Sends the exception data to the Slack channel.
      #
      # When a job fails, a new instance is created and #save is called.
      def save
        return unless self.class.configured?

        report_exception
      end

      # Sends a HTTP Post to the Slack api.
      #
      def report_exception
        # NOTE: if "as_user" is false, messages will be sent from generic "bot" instead of the bot specific name that was used to integrate with your slack account
        # TODO: confirm the above is accurate

        text().each do |txt|
          # According to API documentation: https://api.slack.com/methods/chat.postMessage
          # Message length should be 4,000 char or less, and will be truncated after 40,000 char
          #
          # NOTE: this method's return value appears to only contain the last message that was actually sent
          #       when messages are auto split due to length
          # NOTE: postMessage auto-splitting is not smart enough to split inbetween multiple sections of "```"

          self.class.client.chat_postMessage(channel: self.class.channel, text: txt, as_user: true)
        end
      end

      def overriden_level
        self.class.level_override[exception.to_s]
      end

      # Text to be displayed in the Slack notification
      #
      def text
        # REM: returns an array of strings with length 1+
        Notification.generate(self, overriden_level)
      end
    end
  end
end
