require_relative "lib/hibiscus/version"

Gem::Specification.new do |spec|
  spec.name        = "hibiscus"
  spec.version     = Hibiscus::VERSION
  spec.authors     = ["Blayne Farinha"]
  spec.email       = ["blayne.farinha@gmail.com"]

  spec.summary = "A warden strategy to login via OpenID that can be used in Rails"
  spec.homepage = "https://github.com/blafri/hibiscus"
  spec.license = "MIT"
  spec.required_ruby_version = "~> 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/blafri/hibiscus/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "jwt", "~> 2.7"
  spec.add_dependency "rails", "~> 7.0.0"
  spec.add_dependency "warden", "~> 1.2", ">= 1.2.9"
end
