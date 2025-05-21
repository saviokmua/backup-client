# frozen_string_literal: true

module BackupClient
  module Components
    module Ftp
      module Commands
        class FileUpload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::FtpHelper

          def initialize(ftp_client, file, destination_folder)
            @ftp_client = ftp_client
            @file = file
            @destination_folder = destination_folder
          end

          def call
            File.open(file, "rb") do |file_handle|
              remote_file_path = destination_folder + "/" + File.basename(file)
              remote_file_path = remote_file_path.gsub(%r{//+}, "/")
              ftp_client.putbinaryfile(file_handle, remote_file_path)
              log("Uploaded file #{file} → #{remote_file_path}")
            end
          end

          private

          attr_reader :ftp_client, :file, :destination_folder
        end
      end
    end
  end
end
