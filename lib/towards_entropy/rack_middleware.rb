module TowardsEntropy
  class RackMiddleware
    def initialize(app, config = Config.new)
      @app = app
      @config = config
      @te = TowardsEntropy.new(config)
    end

    def call(env)
      # 1 maybe decompress request
      maybe_decompress_request(env)

      # 2 get dictionary for request
      dictionary = select_dictionary(env)

      # 3 maybe handle head request
      if env['REQUEST_METHOD'] == 'HEAD' && @config.handle_head_requests
        return handle_head_request(env, dictionary)
      end

      # 4 forward request
      status, headers, body = @app.call(env)

      # 4 maybe compress response
      compressed_body, updated_headers = maybe_compress_response(body, request_headers(env), headers, dictionary)

      [status, updated_headers, compressed_body]
    end

    private

    def supports_custom_encoding?(env)
      # Reading the Accept-Encoding header
      accept_encoding = env['HTTP_ACCEPT_ENCODING']

      # Check if the client's Accept-Encoding header includes your custom encoding
      # (replace 'custom-encoding' with whatever name you've chosen for your dictionary-based encoding)
      accept_encoding && accept_encoding.include?('custom-encoding')
    end

    def maybe_decompress_request(env)
      method = env['REQUEST_METHOD']
      return if method != 'POST' && method != 'PUT' && method != 'PATCH'
      return if request_body_empty?(env)
      encoding = env['HTTP_CONTENT_ENCODING']
      return if encoding != Constants::ZSTD && encoding != Constants::SHARED_ZSTD

      dictId = nil
      if encoding == Constants::SHARED_ZSTD
        dictionary = DictionaryStore.get_dictionary(env['HTTP_DICTIONARY_ID'])
        dictId = dictionary.id if dictionary
      end

      decompressed_body = @te.decompress(env['rack.input'].read, dictId)
      env['rack.input'] = StringIO.new(decompressed_body)
    end

    def select_dictionary(env)
      return nil if !accepts_encoding?(env, Constants::SHARED_ZSTD)

      # Shortcut if client forces dictionary
      dictionary_id = env['HTTP_DICTIONARY_ID'] || ''
      if dictionary_id != ''
        return DictionaryStore.get_dictionary(dictionary_id)
      end

      dictionary_ids = (env['HTTP_AVAILABLE_DICTIONARY'] || '')
                       .split(',')
                       .map(&:strip)
                       .reject(&:empty?)
                       .select { |dict_id| dictionary_matches_request?(dict_id, env) }

      DictionaryStore.find_dictionaries(dictionary_ids)
    end

    def dictionary_matches_request?(dictionary_id, env)
      uri = request_uri(env)
      match_patterns = @config.dictionary_match_map.select { |k, v| v == dictionary_id }.keys
      match_patterns.any? { |match_pattern| UrlMatch.matches(match_pattern, uri) }
    end

    def handle_head_request(env, dictionary)
      headers = {}
      if dictionary.nil?
        headers.merge!('Content-Encoding' => Constants::ZSTD)
      else
        headers.merge!('Content-Encoding' => Constants::SHARED_ZSTD)
        headers.merge!('Dictionary-Id' => dictionary.id)
      end

      [200, headers, []]
    end

    # TODO this should be streaming - currently its super ineffecient
    def maybe_compress_response(body, request_headers, response_headers, dictionary)
      if !accepts_encoding?(request_headers, Constants::SHARED_ZSTD) && !accepts_encoding?(request_headers, Constants::ZSTD)
        return [body, response_headers]
      end

      if dictionary.nil?
        response_headers.merge!('Content-Encoding' => Constants::ZSTD)
      else
        response_headers.merge!('Content-Encoding' => Constants::SHARED_ZSTD)
        response_headers.merge!('Dictionary-Id' => dictionary.id)
      end

      compressed_chunks = []
      body.each do |chunk|
        # Compress body using Zstd
        compressed_chunks << @te.compress(chunk, dictionary ? dictionary.id : nil)
      end

      [compressed_chunks, response_headers]
    end

    def request_body_empty?(env)
      input = env['rack.input']
      return true unless input

      body = input.read
      empty = body.nil? || body.strip.empty?

      # Make sure to rewind after reading
      input.rewind

      empty
    end

    def accepts_encoding?(env, encoding)
      accept_encoding = env['HTTP_ACCEPT_ENCODING'] || "" # Fallback to an empty string if the header isn't present
      encodings = accept_encoding.split(',').map(&:strip)
      encodings.include?(encoding)
    end

    def request_headers(env)
      env.select { |key, value| key.include?('HTTP_') }
    end

    def request_uri(env)
      query_string = env['QUERY_STRING']
      if query_string.empty?
        env['SCRIPT_NAME'] + env['PATH_INFO']
      else
        env['SCRIPT_NAME'] + env['PATH_INFO'] + '?' + query_string
      end
    end
  end
end