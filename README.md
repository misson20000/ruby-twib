# ruby-twib
[![Gem Version](https://badge.fury.io/rb/twib.svg)](https://badge.fury.io/rb/twib)

[Twili](https://github.com/misson20000/twili) bridge client for Ruby, providing a way for Ruby applications to send requests to a Twili device via twibd.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'twib'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install twib

## Usage

See the instructions on the [Twili repository](https://github.com/misson20000/twili#twili) for how to set up Twili and twibd.

First, create a [Twib::TwibConnection](https://www.rubydoc.info/gems/twib/Twib/TwibConnection). There is a convenience method [Twib::TwibConnection::connect_unix](https://www.rubydoc.info/gems/twib/Twib/TwibConnection#connect_unix-class_method).
```ruby
> require "twib"
 => true
> tc = Twib::TwibConnection.connect_unix
 => #<Twib::TwibConnection:...>
```

After that, you can list the available devices with [TwibConnection#list_devices](https://www.rubydoc.info/gems/twib/Twib/TwibConnection#list_devices-instance_method), which returns an array of hashes identifying each device.
```ruby
> tc.list_devices
[{"device_id"=>507914862, ...}, ...]
```

Use [TwibConnection#open_device](https://www.rubydoc.info/gems/twib/Twib/TwibConnection#open_device-instance_method) to get a device's [ITwibDeviceInterface](https://www.rubydoc.info/gems/twib/Twib/Interfaces/ITwibDeviceInterface).
```ruby
> tc.open_device(507914862)
 => #<Twib::Interfaces::ITwibDeviceInterface:...>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/misson20000/ruby-twib.
