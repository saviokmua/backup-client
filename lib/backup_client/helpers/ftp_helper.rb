# frozen_string_literal: true

module BackupClient
  module Helpers
    module FtpHelper
      def to_unix_path(path)
        path.sub(/^[A-Za-z]:[\\\/]/, '').last.gsub("\\", "/").gsub(/\/+/, '/')
      end

      def ftp_chdir(ftp_client, path)
        return if ftp_client.pwd == path

        ftp_client.chdir(path)
      end

      def root_chdir(ftp_client)
        ftp_chdir(ftp_client, "/")
      end

      def upload_dir_ftp(local_folder, destination_folder)
        ::BackupClient::Components::Ftp::Commands::FolderUpload.new(
          ftp_client, local_folder.gsub('//', '/'), destination_folder
        ).call
      end

      def upload_file_ftp(local_file_path, remote_folder_path)
        ::BackupClient::Components::Ftp::Commands::FileUpload.new(
          ftp_client, local_file_path.gsub('//', '/'), remote_folder_path
        ).call
      end

      def ftp_dir_exists?(ftp_client, path)
        current = ftp_client.pwd
        ftp_client.chdir(path)
        ftp_client.chdir(current)
        true
      rescue Net::FTPPermError
        false
      end

      def ftp_mkdir_p(path)
        root_chdir(ftp_client)
        return if ftp_mkdir(to_unix_path(path))

        parts = to_unix_path(path).split("/").reject(&:empty?)
        parts.each do |part|
          begin
            ftp_client.mkdir(part)
            # ftp_chdir(ftp_client, path)
            log "Created folder: #{ftp_client.pwd}/#{part}"
          rescue Net::FTPPermError
            # already exists
          end
          ftp_chdir(ftp_client, part)
        end
      end

      def ftp_mkdir(path)
        ftp_client.mkdir(path)
        log "Created folder: #{path}"
        true
      rescue Net::FTPPermError
        false
      end
    end
  end
end
