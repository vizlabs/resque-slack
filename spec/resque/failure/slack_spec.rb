require File.join(File.dirname(__FILE__) + '/../../spec_helper')

describe Resque::Failure::Slack do
  context 'configuration' do
    it 'is not configured by default' do
      expect(described_class.configured?).to be_falsey
    end

    it 'fails without token' do
      expect {
        Resque::Failure::Slack.configure do |config|
          config.channel = 'CHANNEL_ID'
          config.token = nil
        end
      }.to raise_error RuntimeError
      expect(described_class.configured?).to be_falsey
    end

    it 'fails without channel' do
      expect {
        Resque::Failure::Slack.configure do |config|
          config.channel = nil
          config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
        end
      }.to raise_error RuntimeError
      expect(described_class.configured?).to be_falsey
    end

    it 'succeed with a channel and a token' do
      Resque::Failure::Slack.configure do |config|
        config.channel = 'CHANNEL_ID'
        config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
      end
      expect(described_class.configured?).to be_truthy
    end
  end

  context 'notification verbosity' do
    it 'has a configurable verobosity' do
      slack = described_class.new('exception', 'worker', 'queue', 'payload')

      described_class::LEVELS.each do |level|
        Resque::Failure::Slack.configure do |config|
          config.channel = 'CHANNEL_ID'
          config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
          config.level = level
        end
        expect(Resque::Failure::Notification).to receive(:generate).with(slack, level)
        slack.text
      end
    end

    it 'allows verbosity to be overriden' do
      slack = described_class.new('exception', 'worker', 'queue', 'payload')
      Resque::Failure::Slack.configure do |config|
        config.channel = 'CHANNEL_ID'
        config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
        config.level = :minimal
        config.level_override[SignalException] = :compact
      end

      expect(Resque::Failure::Notification).to receive(:generate).with(slack, :minimal)
      slack.text
      slack = described_class.new(SignalException, 'worker', 'queue', 'payload')
      expect(Resque::Failure::Notification).to receive(:generate).with(slack, :compact)
      slack.text
    end
  end

  context 'save' do
    it 'posts a notification upon save if configured' do
      slack = described_class.new('exception', 'worker', 'queue', 'payload')

      Resque::Failure::Slack.configure do |config|
        config.channel = 'CHANNEL_ID'
        config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
      end

      expect(slack).to receive(:report_exception)
      slack.save
    end
  end

  context 'report_exception' do
    it 'sends a notification to Slack' do
      slack = described_class.new('exception', 'worker', 'queue', 'payload')

      Resque::Failure::Slack.configure do |config|
        config.channel = 'CHANNEL_ID'
        config.token = 'xoxb-20119746116-KTEB0R6wBuKOlYGj0unduqzN'
        config.level = :minimal
      end

      # uri = URI.parse(described_class::SLACK_URL + '/chat.postMessage')
      # text = Resque::Failure::Notification.generate(slack, :minimal)
      # params = { 'channel' => 'CHANNEL_ID', 'token' => 'TOKEN', 'text' => text }

      # expect(Net::HTTP).to receive(:post_form)
      #   .with(uri, params)
      #   .and_return(true)

      # slack.report_exception
    end
  end
end
