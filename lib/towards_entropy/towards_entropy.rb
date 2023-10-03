module TowardsEntropy
  class TowardsEntropy
    def initialize(config)
      @config = config
    end

    def compress(data, dictionary_id = nil)
      dictionary = DictionaryStore.get_dictionary(dictionary_id)
      if dictionary.nil?
        return Zstd.compress(data, @config.compression_level)
      end

      Zstd.compress_using_dict(data, dictionary.bytes, @config.compression_level)
    end

    def decompress(compressed_data, dictionary_id = nil)
      dictionary  = DictionaryStore.get_dictionary(dictionary_id)
      if dictionary.nil?
        return Zstd.decompress(compressed_data)
      end

      Zstd.decompress_using_dict(compressed_data, dictionary.bytes)
    end
  end
end