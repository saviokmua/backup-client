# frozen_string_literal: true

module BackupClient
  module Components
    module Scp
      module Commands
        class Upload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::ScpHelper

          SSH_PORT = 22

          def initialize(provider, source_paths, timestamp:, use_timestamp: false)
            @provider      = provider
            @source_paths  = source_paths
            @timestamp     = timestamp
            @use_timestamp = use_timestamp
          end

          def call
            log('[SCP] Start upload!')
            scp_mkdir_p(ssh_client, destination_path)
            log('[SCP] Start upload!')
            scp_processing

            ssh_client.close
            log('[SCP] Finish upload!')
          end

          private

          attr_reader :provider, :source_paths, :use_timestamp, :timestamp

          def ssh_client
            @_ssh_client ||=
              begin
                options = { port: provider['port'] || SSH_PORT }
                if provider['password'].nil?
                  options[:keys] = ['~/.ssh/id_rsa']
                else
                  options[:password] = provider['password']
                end
                log("ssh_client start, options #{options.inspect}")
                res = Net::SSH.start(provider['host'], provider['user'], options)
                log('ssh_client finish')
                res
              end
          end

          def scp_processing
            source_paths.each do |path|
              #folder = path['path'] # to_unix_path(path)

              if File.file?(path['path'])
                log("[SCP] path #{path['path']} is folder")
                upload_file_scp(ssh_client, path['path'], destination_path)
              elsif File.directory?(path['path'])
                log("[SCP] path #{path['path']} is file")
                upload_dir_scp(ssh_client, path, destination_path)
              else
                log "[SCP] Invalid path: #{path['path']}"
              end
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
