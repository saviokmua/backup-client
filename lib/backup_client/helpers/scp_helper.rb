# frozen_string_literal: true

module BackupClient
  module Helpers
    module ScpHelper
      def to_unix_path(path)
        "/#{path.sub(/^[A-Za-z]:[\\\/]/, '')}".gsub("\\", "/").gsub(/\/+/, '/')
      end

      def upload_dir_scp(ssh_client, path, destination_folder)
        ::BackupClient::Components::Scp::Commands::FolderUpload.new(
          ssh_client, path, destination_folder
        ).call
      end

      def upload_file_scp(ssh_client, local_file_path, remote_folder_path)
        ::BackupClient::Components::Scp::Commands::FileUpload.new(
          ssh_client, local_file_path.gsub('//', '/'), remote_folder_path
        ).call
      end

      def scp_mkdir_p(ssh_client, remote_dir)
        cmd = "mkdir -p \"#{remote_dir}\""
        log("[SCP] start mkdir successful!: #{cmd}")
        ssh_client.exec!(cmd)
        log("[SCP] finish mkdir successful!: #{cmd}")
      end
    end
  end
end
