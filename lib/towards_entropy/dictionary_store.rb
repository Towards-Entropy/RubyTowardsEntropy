require_relative "dictionary"

module TowardsEntropy
  class DictionaryStore
    @dictionaries = {}

    class << self
      def add_dictionary(dict)
        @dictionaries[dict.id] = dict
      end

      def get_dictionary(id)
        @dictionaries[id]
      end

      def update_cache_from_dir(path)
        Dir["#{path}/**/*"].each do |entry|
          maybe_update_dictionary(entry)
        end
      end

      def find_dictionaries(dictionary_ids)
        return nil if dictionary_ids.nil?

        dictionary_ids.each do |id|
          dict = DictionaryStore.get_dictionary(id)
          return dict unless dict.nil?
        end
        nil
      end

      private

      def maybe_update_dictionary(path)
        return unless File.file?(path) && File.extname(path) == ".dict"

        dictionary_id = File.basename(path, ".dict")
        bytes = File.read(path)
        add_dictionary(Dictionary.new(dictionary_id, bytes))
      end
    end
  end
end