# frozen_string_literal: true

require_relative "lib/towards_entropy/version"

Gem::Specification.new do |spec|
  spec.name = "towards_entropy"
  spec.version = TowardsEntropy::VERSION
  spec.authors = ["AndrewCEmil"]
  spec.email = ["andrewcemil@gmail.com"]

  spec.summary = "Drop in library for compression dictionary managment"
  spec.description = "Drop in library for compression dictionary managment"
  spec.homepage = "https://github.com/Towards-Entropy/RubyTowardsEntropy"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = "https://github.com/Towards-Entropy/RubyTowardsEntropy"
  spec.metadata["source_code_uri"] = "https://github.com/Towards-Entropy/RubyTowardsEntropy"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rack-test', '~> 1.1'
  spec.add_dependency 'zstd-ruby', '~> 1.5'
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'rack', '~> 2.2'
end
