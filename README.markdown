Resque Slack
============

A [Resque][rq] plugin. Requires Resque >= 1.19 and a >= 1.9 Ruby (MRI, JRuby or Rubinius).

Post a notification in a [Slack][slack] channel when one your jobs fails.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-slack'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-slack

## Usage

Configure your channel, token and notification verbosity:
```ruby
require 'resque/failure/slack'

Resque::Failure::Slack.configure do |config|
  config.channel = 'CHANNEL_ID'    # required
  config.token   = 'TOKEN'         # required
  config.level   = verbosity_level # optional
end

Resque::Failure.backend = Resque::Failure::Slack
```

Level can be:
- verbose: worker, payload, exception and full backtrace
- compact: worker, payload and exception
- minimal: worker and payload only

#### Test Integration

Open `rails console`

```
exception = StandardError.new("Force an exception")
exception.set_backtrace(caller)
# --------------------------
#                                    exception<obj>, worker<str>,             queue<str>,  payload<hash>
failure = Resque::Failure::Slack.new(exception,      "viz-bg:1234:matt_test", "matt_test", {"class"=>"MattTest", "args"=>{foo: 'bar'}})
failure.report_exception()
# OR
slack_client = Resque::Failure::Slack.client
chnl         = Resque::Failure::Slack.channel
slack_client.chat_postMessage(channel: chnl, text: "```#{failure.text}```", as_user: true)
#   AKA
slack_client.chat_postMessage(channel: chnl, text: "test message", as_user: true)
```

Additional reference:
`text = Resque::Failure::Notification.generate(self, overriden_level)`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[rq]: http://github.com/julienXX/resque
[slack]: http://slack.com

[![Build Status](https://travis-ci.org/julienXX/resque-slack.svg)](https://travis-ci.org/julienXX/resque-slack) [![Code Climate](https://codeclimate.com/github/julienXX/resque-slack.svg)](https://codeclimate.com/github/julienXX/resque-slack)
