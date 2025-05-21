# frozen_string_literal: true

require "spec_helper"

RSpec.describe BackupClient::Components::Tasks::Commands::Processor do
  let(:task) do
    {
      "name" => "test_task",
      "paths" => ["/path/to/file.txt", "/path/to/folder"],
      "timestamped_subfolder" => true,
      "providers" => %w[FTP1 LOCAL1]
    }
  end

  let(:config) do
    {
      "providers" => {
        "FTP1" => {
          "type" => "ftp",
          "name" => "FTP1",
          "host" => "ftp.example.com",
          "username" => "user",
          "password" => "pass",
          "path" => "/backup"
        },
        "LOCAL1" => {
          "type" => "local",
          "name" => "LOCAL1",
          "path" => "/backup"
        }
      }
    }
  end

  let(:command) { described_class.new(task, config:) }
  let(:timestamp) { Time.new(2024, 1, 1, 12, 0, 0) }

  before do
    allow(Time).to receive(:now).and_return(timestamp)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp)
    allow(FileUtils).to receive(:cp_r)
    allow(File).to receive(:file?).and_return(true)
    allow(File).to receive(:directory?).and_return(false)
  end

  describe "#call" do
    context "when processing FTP provider" do
      before do
        allow(FileUtils).to receive(:mkdir_p).with("/backup/2024-01-01-12-00-00")
        allow(FileUtils).to receive(:cp).with("/path/to/file.txt", "/backup/2024-01-01-12-00-00")
        allow(FileUtils).to receive(:cp).with("/path/to/folder", "/backup/2024-01-01-12-00-00")
      end

      it "processes the upload" do
        expect(BackupClient::Components::Ftp::Commands::Upload).to receive(:new).with(
          task["paths"],
          config["providers"]["FTP1"],
          timestamp:
        ).and_return(instance_double(BackupClient::Components::Ftp::Commands::Upload, call: nil))

        expect { command.call }.to output(
          "[12:00:00] Processing task test_task\n" \
          "[12:00:00] Processing provider FTP1\n" \
          "[12:00:00] Processing provider LOCAL1\n" \
          "[12:00:00] Copied file /path/to/file.txt → /backup/2024-01-01-12-00-00\n" \
          "[12:00:00] Copied file /path/to/folder → /backup/2024-01-01-12-00-00\n"
        ).to_stdout
      end
    end

    context "when processing local provider" do
      it "processes the upload" do
        allow(BackupClient::Components::Ftp::Commands::Upload).to receive(:new).and_return(
          instance_double(BackupClient::Components::Ftp::Commands::Upload, call: nil)
        )

        expect(FileUtils).to receive(:mkdir_p).with("/backup/2024-01-01-12-00-00")
        expect(FileUtils).to receive(:cp).with("/path/to/file.txt", "/backup/2024-01-01-12-00-00")
        expect(FileUtils).to receive(:cp).with("/path/to/folder", "/backup/2024-01-01-12-00-00")

        expect { command.call }.to output(
          "[12:00:00] Processing task test_task\n" \
          "[12:00:00] Processing provider FTP1\n" \
          "[12:00:00] Processing provider LOCAL1\n" \
          "[12:00:00] Copied file /path/to/file.txt → /backup/2024-01-01-12-00-00\n" \
          "[12:00:00] Copied file /path/to/folder → /backup/2024-01-01-12-00-00\n"
        ).to_stdout
      end
    end

    context "when provider type is not supported" do
      let(:config) do
        {
          "providers" => {
            "UNKNOWN1" => {
              "type" => "unknown",
              "name" => "UNKNOWN1"
            }
          }
        }
      end

      let(:task) do
        {
          "name" => "test_task",
          "paths" => ["/path/to/file.txt"],
          "timestamped_subfolder" => true,
          "providers" => ["UNKNOWN1"]
        }
      end

      it "logs an error" do
        expect { command.call }.to output(
          "[12:00:00] Processing task test_task\n" \
          "[12:00:00] Processing provider UNKNOWN1\n" \
          "[12:00:00] Provider type unknown is not supported\n"
        ).to_stdout
      end
    end

    context "when an error occurs" do
      let(:error) { StandardError.new("Test error") }
      let(:provider) { config["providers"]["FTP1"] }

      before do
        allow(BackupClient::Components::Ftp::Commands::Upload).to receive(:new)
          .with(task["paths"], config["providers"]["FTP1"], timestamp:)
          .and_raise(error)
        allow(FileUtils).to receive(:mkdir_p).with("/backup/2024-01-01-12-00-00")
        allow(FileUtils).to receive(:cp).with("/path/to/file.txt", "/backup/2024-01-01-12-00-00")
        allow(FileUtils).to receive(:cp).with("/path/to/folder", "/backup/2024-01-01-12-00-00")
      end

      it "logs the error and continues" do
        expect { command.call }.to output(
          "[12:00:00] Processing task test_task\n" \
          "[12:00:00] Processing provider FTP1\n" \
          "[12:00:00] Unexpected error: Test error, FTP: FTP1\n" \
          "[12:00:00] Processing provider LOCAL1\n" \
          "[12:00:00] Copied file /path/to/file.txt → /backup/2024-01-01-12-00-00\n" \
          "[12:00:00] Copied file /path/to/folder → /backup/2024-01-01-12-00-00\n"
        ).to_stdout
      end
    end
  end
end
