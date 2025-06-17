# frozen_string_literal: true

module BackupClient
  module Components
    module Scp
      module Commands
        class FileUpload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::ScpHelper

          def initialize(ssh_client, local_file_path, remote_folder_path)
            @ssh_client         = ssh_client
            @local_file_path    = local_file_path
            @remote_folder_path = remote_folder_path
          end

          def call
            remote_file_path = [remote_folder_path, to_unix_path(local_file_path)].join("/").gsub("//", "/")

            scp_mkdir_p(ssh_client, remote_file_path)
            ssh_client.scp.upload!(local_file_path, remote_file_path)

            log "[SCP] Uploaded file #{local_file_path} → #{remote_file_path}"
          rescue StandardError => error
            log "[SCP] Unexpected file upload error. #{local_file_path} → #{remote_file_path}, error: #{error.to_s}"
          end

          private

          attr_reader :ssh_client, :local_file_path, :remote_folder_path
        end
      end
    end
  end
end
