# frozen_string_literal: true

module BackupClient
  module Helpers
    module LogHelper
      def log(msg)
        puts "[#{Time.now.strftime("%H:%M:%S")}] #{msg}"
      end
    end
  end
end
