# TowardsEntropy

RubyTowardsEntropy is middleware for custom dictionary compression using Zstandard in Ruby. Configure the library with dictionaries you have trained as well as path matching for those dictionaries. If you then use this library on both sides of a network request, you will get transparent compression with your custom dictionaries.

Of corse, you can use this library in conjunction with the GoTowardsEntropy golang package - they are designed to interop. Allowing you to have a client in Ruby and server in Go or vice-versa.

## Custom Dictionaries

Zstandard (and other compression systems) allow you to train and utilize custom dictionaries. This dictionaries can dramatically reduce the size of compressed data. The only requirement is that the same dictionary is used for compression and decompression.

Train Zstandard dictionaires like so:

`zstd -q 19 --train training_set/* -o dictionary_name.dict`

or, if your training set is a single large file, you can do something like:

`zstd -q 19 --train training_set/big_file -B10kb -o dictionary_name.dict`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'towards_entropy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install towards_entropy

## Usage

Before using GoTowardsEntropy, make sure you configure the library. Here is an example of how to configure and initialize the library.

```ruby
config = TowardsEntropy::Config.new(
  dictionary_directory: '../../spec/fixtures/dictionaries',
  dictionary_match_map: { '*' => 'supply_chain' }
)
```

They key configuration values are:
1. `dictionary_directory`: a path to a directory that stores all the custom dictionaries you wish to use. These files should be of the form "dictionary_id.dict". So for a dictionary with id "supply_chain", the file would be named "supply_chain.dict"
2. `dictionary_match_map`: a hash object where the keys are "url match" strings and values are dictionary_id strings. In the simple example here, we are matching all urls to the dictionary "supply_chain".

The rest of the configuration options are visible in `lib/towards_entropy/config.rb`

### Middleware

This library is primarily intended to be used as middleware. This means that you can simply configure you server or client to use this library and you should be able to start benefiting from custom dictionary compression.

#### Serverside: Rack Middleware

The serverside middleware for Towards Entropy is implemented as Rack middleware. Rack is used by many popular web frameworks including Rails and Sinatra. Adding usage of Towards Entropy can be as simple as this:

```ruby
config = TowardsEntropy::Config.new(
  dictionary_directory: '../../spec/fixtures/dictionaries',
  dictionary_match_map: { '*' => 'supply_chain' }
)
use TowardsEntropy::RackMiddleware, config
```

This example is fully operational - you can test it out by looking in `examples/client_server`. There are 2 simple steps:

1. Contruct the configuration as needed
2. Configure your web framework to use TowardsEntropy::RackMiddleware (parameterized by RackMiddleware)

#### Clientside: Faraday Middleware

Clientside middleware for Towards Entropy is implemented as Faraday middleware. Unfortunately, Ruby clients are more varied than web frameworks. I chose Faraday as my target, but if there is significant interest in other client libraries, I'm happy to take a look.

Here is an example using Faraday to make a request using the TowardsEntropy middleware:

```ruby
config = TowardsEntropy::Config.new(
  dictionary_directory: '../../spec/fixtures/dictionaries',
  dictionary_match_map: { '*' => 'supply_chain' }
)
conn = Faraday.new(url: 'http://localhost:9292') do |faraday|
  faraday.use TowardsEntropy::FaradayMiddleware, config
  faraday.adapter Faraday.default_adapter
end
```

As with the serverside middleware, this example is fully operational and can be tested out in `examples/client_server`.

### Direct compression usage

In addition to the middleware, there is an interface for directly compressing data. Usage of this interface can be seen in `examples/simple`. The example is copied here:

```ruby
config = TowardsEntropy::Config.new(dictionary_directory: '../../spec/fixtures/dictionaries')
te = TowardsEntropy::TowardsEntropy.new(config)

compressed_without_dictionary = te.compress(data)
compressed_with_dictionary = te.compress(data, 'supply_chain')

decompressed_without_dictionary = te.decompress(compressed_without_dictionary)
decompressed_with_dictionary = te.decompress(compressed_with_dictionary, 'supply_chain')
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Towards-Entropy/RubyTowardsEntropy

## Future work

* Better integration of streaming compression and decompression for middleware (https://github.com/SpringMT/zstd-ruby/pull/62)
* Preflight requests fully clone original request state (https://github.com/lostisland/faraday/discussions/1527)
