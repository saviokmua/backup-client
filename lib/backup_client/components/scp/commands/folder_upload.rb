# frozen_string_literal: true

module BackupClient
  module Components
    module Scp
      module Commands
        class FolderUpload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::ScpHelper

          def initialize(ssh_client, path, destination_folder)
            @ssh_client         = ssh_client
            @path = path
            @local_path         = path['path'].gsub('//', '/')
            @destination_folder = destination_folder
          end

          def call
            current_destination_folder = destination_folder + to_unix_path(local_path)
            scp_mkdir_p(ssh_client, current_destination_folder)

            if path['archive']
              upload_folder_as_archive(path)
            else
              upload_dir(local_path)
            end
          end

          def upload_folder_as_archive(path)
            ::BackupClient::Components::Scp::Commands::ArchiveUpload
              .new(ssh_client, path['path'], destination_folder, archive_password: path.dig('archive', 'password')).call
          end

          def upload_dir(local_path)
            Dir.glob("#{local_path.gsub('\\', '/')}/**/*", File::FNM_DOTMATCH).each do |path|
              basename = File.basename(path)
              next if %w[. .. .git].include?(basename)

              if File.directory?(path)
                scp_mkdir_p(ssh_client, destination_folder + to_unix_path(path))
              else
                upload_file_scp(ssh_client, path, destination_folder)
              end
            end
          end

          private

          attr_reader :ssh_client, :local_path, :destination_folder, :path
        end
      end
    end
  end
end
