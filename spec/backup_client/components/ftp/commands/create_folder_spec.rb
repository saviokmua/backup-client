# frozen_string_literal: true

RSpec.describe BackupClient::Components::Ftp::Commands::CreateFolder do
  let(:ftp_client) { instance_double(Net::FTP) }
  let(:destination_path) { "/test/path" }
  let(:command) { described_class.new(ftp_client, destination_path) }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
  end

  describe "#call" do
    context "when directory already exists" do
      before do
        allow(command).to receive(:ftp_dir_exists?).with(ftp_client, destination_path).and_return(true)
      end

      it "does not create directory" do
        expect(command).not_to receive(:ftp_mkdir)
        expect(command).not_to receive(:ftp_mkdir_p)
        command.call
      end
    end

    context "when directory does not exist and can be created directly" do
      before do
        allow(command).to receive(:ftp_dir_exists?).with(ftp_client, destination_path).and_return(false)
        allow(command).to receive(:ftp_mkdir).with(destination_path).and_return(true)
      end

      it "creates directory directly" do
        expect(command).to receive(:ftp_mkdir).with(destination_path)
        expect(command).not_to receive(:ftp_mkdir_p)
        command.call
      end
    end

    context "when directory does not exist and needs nested creation" do
      before do
        allow(command).to receive(:ftp_dir_exists?).with(ftp_client, destination_path).and_return(false)
        allow(command).to receive(:ftp_mkdir).with(destination_path).and_return(false)
      end

      it "creates directory recursively" do
        expect(command).to receive(:ftp_mkdir).with(destination_path)
        expect(command).to receive(:ftp_mkdir_p).with(destination_path)
        command.call
      end
    end
  end
end
