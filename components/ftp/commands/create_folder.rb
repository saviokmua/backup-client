# frozen_string_literal: true

module Ftp
  module Commands
    class CreateFolder
      include ::LogHelper
      include ::FtpHelper

      def initialize(ftp_client, destination_path)
        @ftp_client       = ftp_client
        @destination_path = destination_path
        @force_root       = force_root
      end

      def call
        return if ftp_dir_exists?(ftp_client, destination_path)
        return if ftp_mkdir(destination_path)

        ftp_mkdir_p(destination_path)
      end

      private

      attr_reader :ftp_client, :destination_path, :force_root

      def skip_processing?
        ftp_dir_exists?(ftp_client, destination_path)
      end
    end
  end
end
