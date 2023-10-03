require 'rack'
require_relative '../../lib/towards_entropy'

class SimpleServer
  def call(env)
    data = File.read("../../spec/fixtures/files/supply_chain/SupplyChainGHGEmissionFactors_v1.2_NAICS_byGHG_USD2021_chunk_9.csv")
    [200, {"Content-Type" => "text/plain"}, [data]]
  end
end

config = TowardsEntropy::Config.new(
  dictionary_directory: '../../spec/fixtures/dictionaries',
  dictionary_match_map: { '*' => 'supply_chain' }
)
use TowardsEntropy::RackMiddleware, config
run SimpleServer.new