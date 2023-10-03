require 'spec_helper'

RSpec.describe TowardsEntropy::FaradayMiddleware do
  let(:test_file_path) { "spec/fixtures/files/supply_chain/SupplyChainGHGEmissionFactors_v1.2_NAICS_byGHG_USD2021_chunk_9.csv" }
  let(:test_data) { File.read(test_file_path) }

  describe '#call' do
    it 'handles non-dictionary zstd correctly' do
      config = TowardsEntropy::Config.new(dictionary_directory: 'spec/fixtures/dictionaries')
      te = TowardsEntropy::TowardsEntropy.new(config)

      conn = Faraday.new do |builder|
        builder.use TowardsEntropy::FaradayMiddleware, config
        builder.adapter :test do |stub|
          stub.get('/path') { [200, { 'Content-Encoding' => TowardsEntropy::Constants::ZSTD }, te.compress(test_data)] }
        end
      end
      response = conn.get('/path')

      # Check request headers
      expect(response.env.request_headers['Accept-Encoding']).to eq(TowardsEntropy::Constants::ZSTD)

      # Check response
      expect(response.body.read).to eq(test_data)
    end

    it 'handles szstd correctly' do
      config = TowardsEntropy::Config.new(
        dictionary_directory: 'spec/fixtures/dictionaries',
        dictionary_match_map: { '*' => 'supply_chain' }
      )
      te = TowardsEntropy::TowardsEntropy.new(config)

      conn = Faraday.new do |builder|
        builder.use TowardsEntropy::FaradayMiddleware, config
        builder.adapter :test do |stub|
          stub.get('/path') { [200, { 'Content-Encoding' => TowardsEntropy::Constants::SHARED_ZSTD, 'Dictionary-Id' => 'supply_chain' }, te.compress(test_data, 'supply_chain')] }
        end
      end

      response = conn.get('/path')

      # Check request headers
      expect(response.env.request_headers['Accept-Encoding']).to eq('szstd,zstd')

      # Check response
      expect(response.body.read).to eq(test_data)
    end

    it 'Compresses post body correctly no dictionary' do
      config = TowardsEntropy::Config.new(dictionary_directory: 'spec/fixtures/dictionaries')
      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_request = nil

      conn = Faraday.new do |builder|
        builder.use TowardsEntropy::FaradayMiddleware, config
        builder.adapter :test do |stub|
          stub.post('/path') do |env|
            compressed_request = env
            [200, {}, '']
          end
        end
      end

      conn.post('/path', test_data)

      # Check request headers
      expect(compressed_request.request_headers['Content-Encoding']).to eq('zstd')
      expect(compressed_request.request_body.read).to eq(te.compress(test_data))
    end

    it 'Compresses post body correctly dictionary' do
      config = TowardsEntropy::Config.new(
        dictionary_directory: 'spec/fixtures/dictionaries',
        dictionary_match_map: { '*' => 'supply_chain' }
      )
      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_request = nil

      conn = Faraday.new do |builder|
        builder.use TowardsEntropy::FaradayMiddleware, config
        builder.adapter :test do |stub|
          stub.post('/path') do |env|
            compressed_request = env
            [200, {}, '']
          end
        end
      end

      conn.post('/path', test_data)

      # Check request headers and body
      expect(compressed_request.request_headers['Content-Encoding']).to eq('szstd')
      expect(compressed_request.request_headers['Dictionary-Id']).to eq('supply_chain')
      expect(compressed_request.request_body.read).to eq(te.compress(test_data, 'supply_chain'))
    end

    it 'Performs preflight properly' do
      config = TowardsEntropy::Config.new(
        dictionary_directory: 'spec/fixtures/dictionaries',
        dictionary_match_map: { '*' => 'supply_chain' },
        preflight_writes: true
      )
      te = TowardsEntropy::TowardsEntropy.new(config)
      compressed_request = nil

      # Stub the head method for any Faraday instance
      expect_any_instance_of(Faraday::Connection).to receive(:head).with("http:/path").and_return(
        instance_double("Faraday::Response", status: 200, headers: {
          'Content-Encoding' => TowardsEntropy::Constants::SHARED_ZSTD,
          'Dictionary-Id' => 'supply_chain'
        }, body: '', success?: true)
      )

      conn = Faraday.new do |builder|
        builder.use TowardsEntropy::FaradayMiddleware, config
        builder.adapter :test do |stub|
          stub.post("/path") do |env|
            compressed_request = env
            [200, {}, '']
          end
        end
      end

      response = conn.post('/path', test_data)

      # Check request headers and body
      expect(compressed_request.request_headers['Content-Encoding']).to eq('szstd')
      expect(compressed_request.request_headers['Dictionary-Id']).to eq('supply_chain')
      expect(compressed_request.request_body.read).to eq(te.compress(test_data, 'supply_chain'))
    end
  end
end