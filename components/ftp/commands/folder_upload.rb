# frozen_string_literal: true

module Ftp
  module Commands
    class FolderUpload
      include LogHelper
      include ::FtpHelper

      def initialize(ftp_client, local_path, destination_folder)
        @ftp_client         = ftp_client
        @local_path         = local_path
        @destination_folder = destination_folder
      end

      def call
        current_destination_folder = destination_folder + local_path
        ftp_mkdir_p(current_destination_folder)
        Dir.glob("#{local_path}/**/*", File::FNM_DOTMATCH).each do |path|
          next if %w[. ..].include?(File.basename(path))

          if File.directory?(path)
            ::Ftp::Commands::CreateFolder.new(ftp_client, destination_folder + path).call
          else
            upload_file_ftp(path, destination_folder)
          end
        end
      end

      private

      attr_reader :ftp_client, :local_path, :destination_folder
    end
  end
end
