# frozen_string_literal: true

module BackupClient
  module Components
    module Ftp
      module Commands
        class FileUpload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::FtpHelper

          def initialize(ftp_client, local_file_path, remote_folder_path)
            @ftp_client         = ftp_client
            @local_file_path    = local_file_path
            @remote_folder_path = remote_folder_path
          end

          def call
            remote_file_path = [remote_folder_path, local_file_path].join("/").gsub("//", "/")

            File.open(local_file_path, "rb") do |file|
              ftp_client.putbinaryfile(file, remote_file_path)
            end

            log "Uploaded file #{local_file_path} → #{remote_file_path}"
          end

          private

          attr_reader :ftp_client, :local_file_path, :remote_folder_path
        end
      end
    end
  end
end
