require 'faraday'
require_relative '../../lib/towards_entropy'

config = TowardsEntropy::Config.new(
  dictionary_directory: '../../spec/fixtures/dictionaries',
  dictionary_match_map: { '*' => 'supply_chain' }
)
conn = Faraday.new(url: 'http://localhost:9292') do |faraday|
  faraday.use TowardsEntropy::FaradayMiddleware, config
  faraday.adapter Faraday.default_adapter
end

response = conn.get('/')
puts "Compressed length: #{response.headers['Content-Length']}"
puts "Uncompressed length: #{response.body.length}"