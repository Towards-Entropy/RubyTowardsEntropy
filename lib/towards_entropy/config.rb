require_relative "dictionary_store"
require_relative "constants"

module TowardsEntropy
  class Config
    attr_accessor :compression_level, :buffer_size, :dictionary_directory,
                  :preflight_writes, :handle_head_requests, :dictionary_match_map, :log_level

    def initialize(
      compression_level: 5,
      buffer_size: 1024,
      dictionary_directory: './dictionaries',
      preflight_writes: false,
      handle_head_requests: false,
      dictionary_match_map: {},
      log_level: nil
    )
      @compression_level = compression_level
      @buffer_size = buffer_size
      @dictionary_directory = dictionary_directory
      @preflight_writes = preflight_writes
      @handle_head_requests = handle_head_requests
      @dictionary_match_map = dictionary_match_map
      @log_level = LogLevel::NONE
      DictionaryStore.update_cache_from_dir(dictionary_directory)
    end
  end
end