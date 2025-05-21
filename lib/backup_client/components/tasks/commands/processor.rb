# frozen_string_literal: true

module BackupClient
  module Components
    module Tasks
      module Commands
        class Processor
          include ::BackupClient::Helpers::LogHelper

          def initialize(task, config:)
            @task          = task
            @providers     = config["providers"]
            @source_paths  = task["paths"]
            @use_timestamp = task.fetch("timestamped_subfolder", true)
            @timestamp     = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
          end

          def call
            log("Processing task #{task["name"]}")

            task["providers"].each do |task_provider|
              provider = fetch_provider(task_provider)
              next if provider.nil?

              log("Processing provider #{task_provider['name']}#{task_provider['type']}")

              processing_task_for_provider(provider)
              # rescue StandardError => e
              #   log(" Unexpected error: #{e}, #{provider["type"].upcase}: #{provider["name"].upcase}")
            end
          end

          private

          attr_reader :task, :providers, :source_paths, :use_timestamp, :timestamp

          def processing_task_for_provider(provider)
            case provider["type"]
            when "ftp"
              upload_to_ftp(provider, source_paths, use_timestamp)
            when "local"
              copy_to_local(provider, source_paths, use_timestamp)
            else
              log("Provider type #{provider["type"]} is not supported")
            end
          end

          def upload_to_ftp(provider, source_paths, use_timestamp)
            ::BackupClient::Components::Ftp::Commands::Upload
              .new(provider, source_paths, use_timestamp: use_timestamp, timestamp: Time.now).call
          end

          def copy_to_local(provider, local_paths, use_timestamp)
            target_path = provider["path"]
            target_path = File.join(target_path, timestamp) if use_timestamp
            FileUtils.mkdir_p(target_path)

            local_paths.each do |path|
              if File.file?(path)
                FileUtils.cp(path, target_path)
                log("Copied file #{path} → #{target_path}")
              elsif File.directory?(path)
                FileUtils.cp_r(path, target_path)
                log("Copied directory #{path} → #{target_path}")
              else
                log("Invalid path: #{path}")
              end
            end
          end

          def fetch_provider(task_provider)
            providers.find do |provider|
              task_provider['name'] == provider['name'] && task_provider['type'] == provider['type']
            end
          end
        end
      end
    end
  end
end
