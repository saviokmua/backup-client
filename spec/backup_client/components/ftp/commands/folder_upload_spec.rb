# frozen_string_literal: true

require "spec_helper"

RSpec.describe BackupClient::Components::Ftp::Commands::FolderUpload do
  let(:ftp_client) { instance_double(Net::FTP) }
  let(:local_path) { "/local/path" }
  let(:remote_path) { "/remote/path" }
  let(:command) { described_class.new(ftp_client, local_path, remote_path) }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))

    # Stub FTP client methods
    allow(ftp_client).to receive(:pwd).and_return("/")
    allow(ftp_client).to receive(:chdir)
    allow(ftp_client).to receive(:mkdir)
    allow(ftp_client).to receive(:putbinaryfile)

    # Stub file system operations
    allow(Dir).to receive(:glob).with("#{local_path}/**/*", File::FNM_DOTMATCH)
                                .and_return([
                                              "/local/path/file.txt",
                                              "/local/path/subfolder",
                                              "/local/path/subfolder/file2.txt",
                                              "/local/path/.git",
                                              "/local/path/..",
                                              "/local/path/."
                                            ])

    allow(File).to receive(:basename).with("/local/path/file.txt").and_return("file.txt")
    allow(File).to receive(:basename).with("/local/path/subfolder").and_return("subfolder")
    allow(File).to receive(:basename).with("/local/path/subfolder/file2.txt").and_return("file2.txt")
    allow(File).to receive(:basename).with("/local/path/.git").and_return(".git")
    allow(File).to receive(:basename).with("/local/path/..").and_return("..")
    allow(File).to receive(:basename).with("/local/path/.").and_return(".")

    allow(File).to receive(:directory?).with("/local/path/file.txt").and_return(false)
    allow(File).to receive(:directory?).with("/local/path/subfolder").and_return(true)
    allow(File).to receive(:directory?).with("/local/path/subfolder/file2.txt").and_return(false)
    allow(File).to receive(:directory?).with("/local/path/.git").and_return(true)
    allow(File).to receive(:directory?).with("/local/path/..").and_return(true)
    allow(File).to receive(:directory?).with("/local/path/.").and_return(true)

    # Stub command methods
    allow(command).to receive(:ftp_mkdir_p)
    allow(command).to receive(:upload_file_ftp)
  end

  describe "#call" do
    context "when creating the destination folder" do
      it "creates the destination folder" do
        expect(command).to receive(:ftp_mkdir_p).with(remote_path + local_path)
        command.call
      end
    end

    context "when creating subfolders" do
      let(:create_folder) { instance_double(BackupClient::Components::Ftp::Commands::CreateFolder) }

      before do
        allow(BackupClient::Components::Ftp::Commands::CreateFolder).to receive(:new).and_return(create_folder)
        allow(create_folder).to receive(:call)
      end

      it "creates subfolders" do
        expect(BackupClient::Components::Ftp::Commands::CreateFolder).to receive(:new)
          .with(ftp_client, remote_path + "/local/path/subfolder")
          .and_return(create_folder)
        expect(create_folder).to receive(:call)

        command.call
      end

      it "skips . and .. directories" do
        expect(BackupClient::Components::Ftp::Commands::CreateFolder).not_to receive(:new)
          .with(ftp_client, remote_path + "/local/path/.")
        expect(BackupClient::Components::Ftp::Commands::CreateFolder).not_to receive(:new)
          .with(ftp_client, remote_path + "/local/path/..")

        command.call
      end

      it "skips .git directory" do
        expect(BackupClient::Components::Ftp::Commands::CreateFolder).not_to receive(:new)
          .with(ftp_client, remote_path + "/local/path/.git")

        command.call
      end
    end

    context "when uploading files" do
      let(:create_folder) { instance_double(BackupClient::Components::Ftp::Commands::CreateFolder) }

      before do
        allow(command).to receive(:ftp_mkdir_p)
        allow(BackupClient::Components::Ftp::Commands::CreateFolder).to receive(:new).and_return(create_folder)
        allow(create_folder).to receive(:call)
      end

      it "uploads files" do
        expect(command).to receive(:upload_file_ftp)
          .with("/local/path/file.txt", remote_path)
        expect(command).to receive(:upload_file_ftp)
          .with("/local/path/subfolder/file2.txt", remote_path)

        command.call
      end
    end
  end
end
