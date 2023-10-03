require 'spec_helper'

RSpec.describe TowardsEntropy::UrlMatch do
  describe '#matches' do
    it 'returns true if the target URL matches the given pattern' do
      test_cases = [
        ["/app1/main*", "https://www.example.com/app1/main_12345.js", true],
        ["main*", "https://www.example.com/app1/main_1.js", true],
        ["main*", "https://www.example.com/app2/main.xyz.js", true],
        ["/app2/main*", "/app2/main_12345.js", true],
        ["/app1/main*", "/app2/main_12345.js", false],
        ["/app1/main*", "main_12345.js", false],
        ["/app1/*", "https://www.example.com/app1/", true],
        ["https://www.example.com/app1/*", "https://www.example.com/app1/main_12345.js", true],
        ["https://www.example.com/app1/*", "https://www.example2.com/app1/main_12345.js", false]
      ]

      test_cases.each do |match_pattern, target_url, expected|
        expect(TowardsEntropy::UrlMatch.matches(match_pattern, target_url)).to eq(expected)
      end
    end
  end
end