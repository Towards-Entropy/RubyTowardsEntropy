require 'uri'

module TowardsEntropy
  class UrlMatch
    def self.matches(match_pattern, target_url)
      # convert wildcard pattern to regular expression
      regex_pattern = Regexp.quote(match_pattern) # QuoteMeta escapes any special characters
      regex_pattern = regex_pattern.gsub('\\*', '.*') # replace escaped * with .*

      re = Regexp.new(regex_pattern)

      # parse the target URL
      u = URI.parse(target_url)

      # decide on which part of URL to match against
      target_string = if u.absolute? # absolute URL
                        # If match_pattern doesn't have a protocol, only match against the path of the target URL
                        if !match_pattern.start_with?('http://') && !match_pattern.start_with?('https://')
                          u.path
                        else
                          u.to_s
                        end
                      else # relative URL or path
                        u.path
                      end

      re.match?(target_string)
    end
  end
end