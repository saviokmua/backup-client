# frozen_string_literal: true

require "yaml"
require "net/ftp"
require 'net/ssh'
require 'net/scp'
require "fileutils"
require "time"
require_relative "backup_client/helpers/log_helper"
require_relative "backup_client/helpers/ftp_helper"
require_relative "backup_client/helpers/scp_helper"
require_relative "backup_client/components/ftp/commands/create_folder"
require_relative "backup_client/components/ftp/commands/file_upload"
require_relative "backup_client/components/ftp/commands/folder_upload"
require_relative "backup_client/components/ftp/commands/upload"
require_relative "backup_client/components/tasks/commands/processor"
require_relative "backup_client/components/scp/commands/file_upload"
require_relative "backup_client/components/scp/commands/folder_upload"
require_relative "backup_client/components/scp/commands/archive_upload"
require_relative "backup_client/components/scp/commands/upload"

Dir.glob("components/**/*.rb").sort.each do |file|
  require_relative file
end

module BackupClient
  VERSION = "0.1.10"

  class Processor
    include ::BackupClient::Helpers::LogHelper

    def initialize(config)
      @config = config
      @tasks  = config["tasks"]
    end

    def call
      return false if tasks.nil?

      tasks.each { |task| processing_task(task) }
    end

    private

    attr_reader :tasks, :config

    def processing_task(task)
      ::BackupClient::Components::Tasks::Commands::Processor.new(task, config: config).call
    end
  end
end
