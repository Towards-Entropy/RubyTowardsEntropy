require 'spec_helper'
require 'rack/test'
require 'towards_entropy'

RSpec.describe TowardsEntropy::RackMiddleware do
  include Rack::Test::Methods
  attr_accessor :last_received_env

  let(:test_file_path) { "spec/fixtures/files/supply_chain/SupplyChainGHGEmissionFactors_v1.2_NAICS_byGHG_USD2021_chunk_9.csv" }
  let(:dictionary_bytes) { File.read(dictionary_path) }
  let(:test_data) { File.read(test_file_path) }

  let(:config) do
    TowardsEntropy::Config.new(
      dictionary_directory: 'spec/fixtures/dictionaries',
    )
  end
  let(:shared_zstd_config) do
    TowardsEntropy::Config.new(
      dictionary_directory: 'spec/fixtures/dictionaries',
      dictionary_match_map: { '*' => 'supply_chain' }
    )
  end
  let(:shared_handle_head_config) do
    TowardsEntropy::Config.new(
      dictionary_directory: 'spec/fixtures/dictionaries',
      dictionary_match_map: { '*' => 'supply_chain' },
      handle_head_requests: true
    )
  end

  def build_app_with_config(config)
    builder = Rack::Builder.new
    builder.use Rack::Lint  # <-- Optional: Use Rack::Lint for validation
    builder.use TowardsEntropy::RackMiddleware, config
    app_lambda = lambda do |env|
      self.last_received_env = env.dup
      [200, {}, [test_data]]
    end
    builder.run app_lambda

    builder.to_app
  end

  describe '#call' do
    it 'returns a successful response with Zstd encoding' do
      def app
        build_app_with_config(config)
      end
      header 'Accept-Encoding', 'zstd'
      get '/test', {}
      expect(last_response.status).to eq(200)
      puts last_response.headers
      expect(last_response.headers['Content-Encoding']).to eq('zstd')
      expect(last_response.headers['Dictionary-Id']).to be_nil

      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_test_data = te.compress(test_data)
      expect(last_response.body).to eq(compressed_test_data)
    end

    it 'returns a successful response with shared Zstd encoding' do
      def app
        build_app_with_config(shared_zstd_config)
      end
      header 'Accept-Encoding', 'zstd, szstd'
      header 'Available-Dictionary', 'supply_chain'
      get '/test', {}
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Encoding']).to eq('szstd')
      expect(last_response.headers['Dictionary-Id']).to eq('supply_chain')

      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_test_data = te.compress(test_data, 'supply_chain')
      expect(last_response.body).to eq(compressed_test_data)
    end

    it 'returns a successful response with shared Zstd encoding for HEAD requests' do
      def app
        build_app_with_config(shared_handle_head_config)
      end
      builder = Rack::Builder.new
      builder.use TowardsEntropy::RackMiddleware, config
      builder.run app
      rack_app = builder.to_app
      header 'Accept-Encoding', 'zstd, szstd'
      header 'Available-Dictionary', 'supply_chain'
      head '/test', {}
      puts last_response.headers
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Encoding']).to eq('szstd')
      expect(last_response.headers['Dictionary-Id']).to eq('supply_chain')
      expect(last_response.body).to be_empty
    end

    it 'decompresses the body of a post request no dictionary' do
      def app
        build_app_with_config(shared_zstd_config)
      end

      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_test_data = te.compress(test_data)

      builder = Rack::Builder.new
      builder.use TowardsEntropy::RackMiddleware, config
      builder.run app
      rack_app = builder.to_app

      header 'Content-Encoding', 'zstd'
      post '/test', compressed_test_data

      expect(last_response.status).to eq(200)
      received_body = self.last_received_env['rack.input'].read
      expect(received_body).to eq(test_data)
    end

    it 'decompresses the body of a post request dictionary' do
      def app
        build_app_with_config(shared_zstd_config)
      end

      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_test_data = te.compress(test_data, 'supply_chain')

      builder = Rack::Builder.new
      builder.use TowardsEntropy::RackMiddleware, config
      builder.run app
      rack_app = builder.to_app

      header 'Content-Encoding', 'szstd'
      header 'Dictionary-Id', 'supply_chain'
      post '/test', compressed_test_data

      expect(last_response.status).to eq(200)
      received_body = self.last_received_env['rack.input'].read
      expect(received_body).to eq(test_data)
    end
  end
end