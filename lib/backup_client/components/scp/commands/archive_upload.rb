# frozen_string_literal: true

module BackupClient
  module Components
    module Scp
      module Commands
        class ArchiveUpload
          include ::BackupClient::Helpers::LogHelper
          include ::BackupClient::Helpers::ScpHelper

          def initialize(ssh_client, local_path, destination_folder, archive_password: nil)
            @ssh_client         = ssh_client
            @local_path         = local_path.gsub('//', '/')
            @destination_folder = destination_folder
            @archive_password = archive_password
          end

          def call
            require 'tempfile'
            require 'zlib'
            require 'archive/tar/minitar'
            require 'ruby-progressbar'
            require 'seven_zip_ruby'
            require 'shellwords'

            # Create destination folder if it doesn't exist
            scp_mkdir_p(ssh_client, destination_folder)

            # Create temporary file for the archive
            Tempfile.open(['archive', archive_extension]) do |temp_file|
              if archive_password
                create_encrypted_archive(temp_file)
              else
                create_regular_archive(temp_file)
              end

              # Get file size for progress bar
              file_size = File.size(temp_file.path)

              # Generate archive filename
              archive_name = "#{File.basename(local_path)}#{archive_extension}"
              @remote_path = File.join(destination_folder, local_path, archive_name)

              # Create progress bar
              progress = ProgressBar.create(
                title: "Uploading",
                total: file_size,
                format: '%t: |%B| %p%% %e',
                output: $stderr
              )

              # Upload the archive with progress tracking
              ssh_client.scp.upload!(temp_file.path, @remote_path) do |chunk, name, sent, total|
                progress.progress = sent
              end

              progress.finish
              log "[SCP] Uploaded archive #{local_path} → #{@remote_path}"
            end
          rescue StandardError => error
            log "[SCP] Unexpected archive upload error. #{local_path} → #{@remote_path}, error: #{error.to_s}"
          end

          private

          attr_reader :ssh_client, :local_path, :destination_folder, :archive_password

          def create_encrypted_archive(temp_file)
            escaped_password = Shellwords.escape(archive_password)
            escaped_output_path = Shellwords.escape(temp_file.path)
            
            # Use the full path to 7zz (Homebrew's 7-Zip)
            seven_zip_path = '/usr/local/bin/7zz'
            unless File.exist?(seven_zip_path)
              raise "7-Zip not found at #{seven_zip_path}. Please install it with: brew install sevenzip"
            end

            # Create a temporary directory for the files
            Dir.mktmpdir do |temp_dir|
              # First create a tar archive
              tar_path = File.join(temp_dir, 'archive.tar')
              File.open(tar_path, 'wb') do |tar_file|
                Archive::Tar::Minitar.pack(local_path, tar_file) do |entry|
                  next if entry.name.start_with?('.git/') # Skip git files
                  entry
                end
              end

              # Verify the tar file was created
              unless File.exist?(tar_path) && File.size?(tar_path)
                raise "Failed to create tar archive at #{tar_path}"
              end

              # Then create a password-protected 7z archive
              escaped_tar_path = Shellwords.escape(tar_path)
              
              # Remove the output file if it exists
              FileUtils.rm_f(temp_file.path)
              
              # Use 7z to create the archive from the tar file
              cmd = "#{seven_zip_path} a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -p#{escaped_password} #{escaped_output_path} #{escaped_tar_path}"
              log "[SCP] Creating encrypted archive with command: #{cmd.gsub(escaped_password, '****')}"
              
              # Run the command and capture both stdout and stderr
              output = `#{cmd} 2>&1`
              exit_status = $?.exitstatus
              
              # Log the command output for debugging
              log "[SCP] 7z command output: #{output}"
              log "[SCP] 7z exit status: #{exit_status}"
              
              # Verify the output file was created
              unless File.exist?(temp_file.path) && File.size?(temp_file.path)
                raise "Failed to create 7z archive at #{temp_file.path}"
              end
              
              unless exit_status == 0
                raise "Failed to create encrypted archive: #{output}"
              end
            end
          end

          def create_regular_archive(temp_file)
            File.open(temp_file.path, 'wb') do |file|
              gzip_io = Zlib::GzipWriter.new(file)
              Archive::Tar::Minitar.pack(local_path, gzip_io) do |entry|
                next if entry.name.start_with?('.git/') # Skip git files
                entry
              end
              gzip_io.close
            end
          end

          def archive_extension
            archive_password ? '.7z' : '.tar.gz'
          end
        end
      end
    end
  end
end
