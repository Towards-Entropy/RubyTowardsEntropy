# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TowardsEntropy::TowardsEntropy do
  let(:dictionary_path) { "spec/fixtures/dictionaries/supply_chain.dict" }
  let(:dictionaries_path) { "spec/fixtures/dictionaries/" }
  let(:test_file_path) { "spec/fixtures/files/supply_chain/SupplyChainGHGEmissionFactors_v1.2_NAICS_byGHG_USD2021_chunk_9.csv" }
  let(:config) { TowardsEntropy::Config.new(dictionary_directory: dictionaries_path) }
  let(:te) { TowardsEntropy::TowardsEntropy.new(config) }

  # Load dictionary and test data from file
  let(:dictionary_bytes) { File.read(dictionary_path) }
  let(:test_data) { File.read(test_file_path) }

  describe '#compress' do
    it 'compresses data without a dictionary' do
      compressed_data = te.compress(test_data)
      expect(compressed_data).not_to be_nil
      expect(compressed_data).not_to eq(test_data)
    end

    context 'with a dictionary' do
      it 'compresses data with a dictionary' do
        compressed_data = te.compress(test_data, "supply_chain")
        expect(compressed_data).not_to be_nil
        expect(compressed_data).not_to eq(test_data)
      end
    end
  end

  describe '#decompress' do
    it 'decompresses data without a dictionary' do
      compressed_data = Zstd.compress(test_data)
      decompressed_data = te.decompress(compressed_data)
      expect(decompressed_data).to eq(test_data)
    end

    context 'with a dictionary' do
      it 'decompresses data with a dictionary' do
        compressed_data = Zstd.compress_using_dict(test_data, dictionary_bytes)
        decompressed_data = te.decompress(compressed_data, "supply_chain")
        expect(decompressed_data).to eq(test_data)
      end
    end
  end
end
