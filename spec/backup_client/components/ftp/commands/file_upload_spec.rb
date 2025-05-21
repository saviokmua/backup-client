# frozen_string_literal: true

require "spec_helper"

RSpec.describe BackupClient::Components::Ftp::Commands::FileUpload do
  let(:ftp_client) { instance_double(Net::FTP) }
  let(:file) { "/local/path/file.txt" }
  let(:destination_folder) { "/remote/path" }
  let(:command) { described_class.new(ftp_client, file, destination_folder) }
  let(:file_handle) { instance_double(File) }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
    allow(File).to receive(:basename).with(file).and_return("file.txt")
    allow(File).to receive(:open).with(file, "rb").and_yield(file_handle)
  end

  describe "#call" do
    it "uploads file to remote path" do
      expect(ftp_client).to receive(:putbinaryfile)
        .with(file_handle, "/remote/path/file.txt")

      expect { command.call }.to output(
        "[12:00:00] Uploaded file /local/path/file.txt → /remote/path/file.txt\n"
      ).to_stdout
    end

    context "when paths have double slashes" do
      let(:destination_folder) { "/remote/path/" }

      it "normalizes the remote path" do
        expect(ftp_client).to receive(:putbinaryfile)
          .with(file_handle, "/remote/path/file.txt")

        expect { command.call }.to output(
          "[12:00:00] Uploaded file /local/path/file.txt → /remote/path/file.txt\n"
        ).to_stdout
      end
    end
  end
end
