# frozen_string_literal: true

require "bundler/setup"
require "backup_client"
require "backup_client/helpers/log_helper"
require "backup_client/helpers/ftp_helper"
require "backup_client/components/ftp/commands/upload"
require "backup_client/components/local/commands/upload"
require "backup_client/components/tasks/commands/processor"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.order = :random
  Kernel.srand config.seed
end
