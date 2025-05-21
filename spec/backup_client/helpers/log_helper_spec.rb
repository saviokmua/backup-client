# frozen_string_literal: true

RSpec.describe BackupClient::Helpers::LogHelper do
  let(:test_class) do
    Class.new do
      include BackupClient::Helpers::LogHelper
    end
  end

  let(:instance) { test_class.new }

  describe "#log" do
    it "outputs a message with timestamp" do
      time = Time.new(2024, 1, 1, 12, 0, 0)
      allow(Time).to receive(:now).and_return(time)

      expect { instance.log("test message") }.to output("[12:00:00] test message\n").to_stdout
    end
  end
end
