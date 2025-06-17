# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name = "backup_client"
  spec.version = "0.1.11"
  spec.authors = ["Alex"]
  spec.email = ["savio.km.ua@gmail.com"]

  spec.summary = "Backup client"
  spec.description = "A simple gem for doing backups"
  spec.homepage = "https://rubygems.org/gems/backup_client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.8"
  # spec.metadata["allowed_push_host"] = "RubyGems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/saviokmua/backup-client"
  spec.metadata["changelog_uri"] = "https://github.com/saviokmua/backup-client/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "net-ftp", "~> 0.2.0"
  spec.add_dependency "archive-tar-minitar", '~> 0.12'
  spec.add_dependency "ruby-progressbar", "~> 1.13.0"
  spec.add_dependency "seven_zip_ruby", "~> 1.3.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
