require 'faraday'
require 'stringio'

module TowardsEntropy
  class FaradayMiddleware
    def initialize(app, config)
      @app = app
      @config = config
      @te = TowardsEntropy.new(config)
    end

    def call(env)
      method = env[:method].to_s.upcase
      if method == "GET" || method == "HEAD"
        call_read(env)
      elsif method == "POST" || method == "PUT" || method == "PATCH"
        call_write(env)
      else
        @app.call(env)
      end
    end

    def call_read(env)
      add_read_headers(env)
      @app.call(env).on_complete do |response_env|
        decompress_response(response_env)
      end
    end

    def call_write(env)
      if env[:body].nil?
        return @app.call(env)
      end

      # TODO need to handle no-compression case
      dict_id = get_dictionary_id_for_write(env)
      add_write_headers(env, dict_id)
      compress_data(env, dict_id)
      @app.call(env)
    end

    private

    def add_read_headers(env)
      env[:request_headers]["Accept-Encoding"] = Constants::ZSTD

      dict_ids = find_matching_dict_ids(env)
      if dict_ids.length > 0
        env[:request_headers]["Accept-Encoding"] = [Constants::SHARED_ZSTD, Constants::ZSTD].join(",")
        env[:request_headers]["Available-Dictionary"] = dict_ids.join(",")
      end
    end

    def add_write_headers(env, dict_id)
      if dict_id.nil?
        env[:request_headers]["Content-Encoding"] = Constants::ZSTD
      else
        env[:request_headers]["Content-Encoding"] = Constants::SHARED_ZSTD
        env[:request_headers]["Dictionary-Id"] = dict_id
      end
    end

    def get_dictionary_id_for_write(env)
      if @config.preflight_writes
        response = preflight_head_request(env)
        puts response.headers
        puts response.success?
        puts response
        return nil if !response.success?
        response.headers['Dictionary-Id']
      else
        dictionaries = find_matching_dict_ids(env)
        dictionaries.first unless dictionaries.empty?
      end
    end

    def preflight_head_request(env)
      conn = Faraday.new { |builder| builder.use FaradayMiddleware, @config }
      conn.head(env[:url].to_s)
    end

    def find_matching_dict_ids(env)
      url = env[:url]

      full_url = url.to_s

      if !url.absolute? && (url.host.nil? || url.host.empty?)
        full_url = "#{url.scheme}://#{url.host}#{url.to_s}"
      end

      match_map = @config.dictionary_match_map
      matching_ids = []

      match_map.each do |pattern, id|
        next if pattern.empty?
        if UrlMatch.matches(pattern, full_url)
          matching_ids << id
        end
      end

      matching_ids
    end

    def decompress_response(response_env)
      encoding = response_env[:response_headers]["Content-Encoding"]
      return if encoding != Constants::ZSTD && encoding != Constants::SHARED_ZSTD

      dict_id = response_env[:response_headers]["Dictionary-Id"]
      response_env[:body] = StringIO.new(@te.decompress(response_env[:body], dict_id))
    end

    def compress_data(env, dict_id)
      env[:body] = StringIO.new(@te.compress(env[:body], dict_id))
    end
  end
end