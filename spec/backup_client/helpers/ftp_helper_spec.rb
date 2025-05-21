# frozen_string_literal: true

RSpec.describe BackupClient::Helpers::FtpHelper do
  let(:test_class) do
    Class.new do
      include BackupClient::Helpers::FtpHelper
      include BackupClient::Helpers::LogHelper
      include RSpec::Mocks::ExampleMethods

      attr_reader :ftp_client

      def initialize
        @ftp_client = double(Net::FTP)
      end
    end
  end

  let(:instance) { test_class.new }
  let(:ftp_client) { instance.ftp_client }

  before do
    allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
  end

  describe "#ftp_chdir" do
    context "when current directory is different from target" do
      before do
        allow(ftp_client).to receive(:pwd).and_return("/current")
        allow(ftp_client).to receive(:chdir)
      end

      it "changes directory" do
        expect(ftp_client).to receive(:chdir).with("/target")
        instance.ftp_chdir(ftp_client, "/target")
      end
    end

    context "when current directory is same as target" do
      before do
        allow(ftp_client).to receive(:pwd).and_return("/target")
      end

      it "does not change directory" do
        expect(ftp_client).not_to receive(:chdir)
        instance.ftp_chdir(ftp_client, "/target")
      end
    end
  end

  describe "#root_chdir" do
    it "changes to root directory" do
      expect(instance).to receive(:ftp_chdir).with(ftp_client, "/")
      instance.root_chdir(ftp_client)
    end
  end

  describe "#ftp_dir_exists?" do
    context "when directory exists" do
      before do
        allow(ftp_client).to receive(:pwd).and_return("/current")
        allow(ftp_client).to receive(:chdir)
      end

      it "returns true" do
        expect(instance.ftp_dir_exists?(ftp_client, "/test")).to be true
      end
    end

    context "when directory does not exist" do
      before do
        allow(ftp_client).to receive(:pwd).and_return("/current")
        allow(ftp_client).to receive(:chdir).and_raise(Net::FTPPermError)
      end

      it "returns false" do
        expect(instance.ftp_dir_exists?(ftp_client, "/test")).to be false
      end
    end
  end

  describe "#ftp_mkdir" do
    context "when directory creation succeeds" do
      before do
        allow(ftp_client).to receive(:mkdir)
      end

      it "creates directory and returns true" do
        expect(ftp_client).to receive(:mkdir).with("/test")
        expect { instance.ftp_mkdir("/test") }.to output("[12:00:00] Created folder: /test\n").to_stdout
        expect(instance.ftp_mkdir("/test")).to be true
      end
    end

    context "when directory creation fails" do
      before do
        allow(ftp_client).to receive(:mkdir).and_raise(Net::FTPPermError)
      end

      it "returns false" do
        expect(instance.ftp_mkdir("/test")).to be false
      end
    end
  end

  describe "#ftp_mkdir_p" do
    before do
      allow(instance).to receive(:root_chdir)
      allow(ftp_client).to receive(:pwd).and_return("/")
      allow(ftp_client).to receive(:chdir)
    end

    context "when directory already exists" do
      before do
        allow(instance).to receive(:ftp_mkdir).and_return(true)
      end

      it "does not create nested directories" do
        expect(instance).to receive(:ftp_mkdir).with("/test/nested").and_return(true)
        expect(instance).not_to receive(:ftp_mkdir).with("/test")
        expect(instance).not_to receive(:ftp_mkdir).with("nested")
        instance.ftp_mkdir_p("/test/nested")
      end
    end

    context "when directory does not exist" do
      before do
        allow(instance).to receive(:ftp_mkdir).and_return(false)
        allow(ftp_client).to receive(:mkdir)
      end

      it "creates nested directories" do
        expect(instance).to receive(:ftp_mkdir).with("/test/nested").and_return(false)
        expect(ftp_client).to receive(:mkdir).with("test")
        expect(ftp_client).to receive(:mkdir).with("nested")
        instance.ftp_mkdir_p("/test/nested")
      end
    end
  end
end
