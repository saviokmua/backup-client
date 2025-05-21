# frozen_string_literal: true

require "fileutils"
require "backup_client/helpers/log_helper"

module BackupClient
  module Components
    module Local
      module Commands
        class Upload
          include BackupClient::Helpers::LogHelper

          def initialize(paths, provider, use_timestamp = true)
            @paths = paths
            @provider = provider
            @use_timestamp = use_timestamp
            @timestamp = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
          end

          def call
            create_destination_folder
            upload_files
            upload_folders
          end

          private

          def create_destination_folder
            FileUtils.mkdir_p(destination_path)
          end

          def upload_files
            @paths["files"]&.each do |file|
              next unless File.file?(file)

              target_path = File.join(destination_path, File.basename(file))
              FileUtils.cp(file, target_path)
              log("Copied file #{file} → #{target_path}")
            end
          end

          def upload_folders
            @paths["folders"]&.each do |folder|
              next unless File.directory?(folder)

              target_path = File.join(destination_path, File.basename(folder))
              FileUtils.cp_r(folder, target_path)
              log("Copied directory #{folder} → #{target_path}")
            end
          end

          def destination_path
            path = @provider["path"]
            path = File.join(path, @timestamp) if @use_timestamp
            path
          end
        end
      end
    end
  end
end
