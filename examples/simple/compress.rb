require_relative "../../lib/towards_entropy"

data = File.read("../../spec/fixtures/files/supply_chain/SupplyChainGHGEmissionFactors_v1.2_NAICS_byGHG_USD2021_chunk_9.csv")

config = TowardsEntropy::Config.new(dictionary_directory: '../../spec/fixtures/dictionaries')
te = TowardsEntropy::TowardsEntropy.new(config)

compressed_without_dictionary = te.compress(data)
compressed_with_dictionary = te.compress(data, 'supply_chain')

decompressed_without_dictionary = te.decompress(compressed_without_dictionary)
decompressed_with_dictionary = te.decompress(compressed_with_dictionary, 'supply_chain')

puts "Original length: #{data.length}"
puts "Compressed length without dictionary: #{compressed_without_dictionary.length}"
puts "Compressed length with dictionary: #{compressed_with_dictionary.length}"

if data != decompressed_without_dictionary || data != decompressed_with_dictionary
  raise "Data mismatch"
end