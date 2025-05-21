# frozen_string_literal: true

module BackupClient
  module Components
    module Ftp
      module Commands
        class Upload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::FtpHelper

          FTP_PORT = 21

          def initialize(provider, source_paths, timestamp:, use_timestamp: false)
            @provider      = provider
            @source_paths  = source_paths
            @timestamp     = timestamp
            @use_timestamp = use_timestamp
          end

          def call
            ftp_mkdir_p(destination_path)

            ftp_processing

            ftp_client.close
          end

          private

          attr_reader :provider, :source_paths, :use_timestamp, :timestamp

          def ftp_processing
            source_paths.each do |path|
              folder = to_unix_path(path)

              if File.file?(folder)
                upload_file_ftp(folder, destination_path)
              elsif File.directory?(folder)
                upload_dir_ftp(folder, destination_path)
              else
                log "Invalid path: #{folder}"
              end
            end
          end

          def to_unix_path(path)
            if Regexp.new('^[A-Za-z]:\\\\') =~ path
              path.sub(/^[A-Za-z]:\\/, '/').gsub('\\', '/')
            else
              path
            end
          end

          def ftp_client
            @ftp_client ||=
              begin
                ftp = Net::FTP.new
                ftp.connect(provider["host"], FTP_PORT)
                ftp.login(provider["user"], provider["password"])
                ftp.passive = true
                ftp
              end
          end

          def destination_path
            @destination_path ||=
              begin
                folder = provider["path"]
                folder = "/#{folder}" unless folder.start_with?("/")
                folder += "/#{timestamp}" if use_timestamp
                folder.gsub("//", "/")
              end
          end
        end
      end
    end
  end
end
