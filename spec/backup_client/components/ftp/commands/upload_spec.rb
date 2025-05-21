# frozen_string_literal: true

RSpec.describe BackupClient::Components::Ftp::Commands::Upload do
  let(:provider) do
    {
      "host" => "ftp.example.com",
      "user" => "user",
      "password" => "password",
      "path" => "backups"
    }
  end
  let(:source_paths) { ["/path/to/file.txt", "/path/to/folder"] }
  let(:timestamp) { "20240101" }
  let(:use_timestamp) { true }
  let(:command) { described_class.new(provider, source_paths, timestamp:, use_timestamp:) }
  let(:ftp_client) { instance_double(Net::FTP) }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
    allow(Net::FTP).to receive(:new).and_return(ftp_client)
    allow(ftp_client).to receive(:connect)
    allow(ftp_client).to receive(:login)
    allow(ftp_client).to receive(:passive=)
    allow(ftp_client).to receive(:close)
    allow(ftp_client).to receive(:pwd).and_return("/")
    allow(ftp_client).to receive(:chdir)
    allow(ftp_client).to receive(:mkdir)
    allow(ftp_client).to receive(:putbinaryfile)
    allow(File).to receive(:open).with("/path/to/file.txt", "rb").and_yield(instance_double(File))
  end

  describe "#call" do
    before do
      allow(File).to receive(:file?).with("/path/to/file.txt").and_return(true)
      allow(File).to receive(:file?).with("/path/to/folder").and_return(false)
      allow(File).to receive(:directory?).with("/path/to/file.txt").and_return(false)
      allow(File).to receive(:directory?).with("/path/to/folder").and_return(true)
    end

    it "creates destination folder" do
      expect(command).to receive(:ftp_mkdir_p).with("/backups/20240101")
      command.call
    end

    it "uploads files and folders" do
      expect(command).to receive(:upload_file_ftp).with("/path/to/file.txt", "/backups/20240101")
      expect(command).to receive(:upload_dir_ftp).with("/path/to/folder", "/backups/20240101")
      command.call
    end

    it "closes FTP connection" do
      expect(ftp_client).to receive(:close)
      command.call
    end
  end

  describe "#ftp_client" do
    it "connects to FTP server" do
      expect(ftp_client).to receive(:connect).with("ftp.example.com", 21)
      expect(ftp_client).to receive(:login).with("user", "password")
      expect(ftp_client).to receive(:passive=).with(true)
      command.send(:ftp_client)
    end
  end

  describe "#destination_path" do
    context "when use_timestamp is true" do
      it "includes timestamp in path" do
        expect(command.send(:destination_path)).to eq("/backups/20240101")
      end
    end

    context "when use_timestamp is false" do
      let(:use_timestamp) { false }

      it "does not include timestamp in path" do
        expect(command.send(:destination_path)).to eq("/backups")
      end
    end

    context "when path does not start with slash" do
      let(:provider) do
        {
          "host" => "ftp.example.com",
          "user" => "user",
          "password" => "password",
          "path" => "backups"
        }
      end

      it "adds leading slash" do
        expect(command.send(:destination_path)).to eq("/backups/20240101")
      end
    end

    context "when path has double slashes" do
      let(:provider) do
        {
          "host" => "ftp.example.com",
          "user" => "user",
          "password" => "password",
          "path" => "/backups/"
        }
      end

      it "normalizes path" do
        expect(command.send(:destination_path)).to eq("/backups/20240101")
      end
    end
  end
end
