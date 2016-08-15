require 'resque'
require 'slack-ruby-client'
require_relative 'notification.rb'

module Resque
  module Failure
    class Slack < Base
      LEVELS = %i(verbose compact minimal)

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
        self.class.client.chat_postMessage(channel: self.class.channel, text: "```#{text}```", as_user: true)
      end

      def overriden_level
        self.class.level_override[exception.to_s]
      end

      # Text to be displayed in the Slack notification
      #
      def text
        Notification.generate(self, overriden_level)
      end
    end
  end
end
