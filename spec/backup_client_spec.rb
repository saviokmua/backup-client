# frozen_string_literal: true

RSpec.describe BackupClient do
  it "has a version number" do
    expect(BackupClient::VERSION).not_to be nil
  end

  it "defines the Processor class" do
    expect(BackupClient::Processor).to be_a(Class)
  end
end

RSpec.describe BackupClient::Processor do
  let(:valid_config) do
    {
      "tasks" => [
        {
          "name" => "test_task",
          "source" => "/path/to/source",
          "destination" => "/path/to/destination"
        }
      ]
    }
  end

  let(:invalid_config) { {} }

  describe "#initialize" do
    it "initializes with valid config" do
      processor = described_class.new(valid_config)
      expect(processor).to be_a(BackupClient::Processor)
    end

    it "initializes with invalid config" do
      processor = described_class.new(invalid_config)
      expect(processor).to be_a(BackupClient::Processor)
    end
  end

  describe "#call" do
    context "with valid tasks" do
      let(:processor) { described_class.new(valid_config) }
      let(:task_processor) { instance_double(BackupClient::Components::Tasks::Commands::Processor) }

      before do
        allow(BackupClient::Components::Tasks::Commands::Processor).to receive(:new)
          .and_return(task_processor)
        allow(task_processor).to receive(:call)
      end

      it "processes each task" do
        expect(task_processor).to receive(:call).once
        processor.call
      end
    end

    context "with nil tasks" do
      let(:processor) { described_class.new(invalid_config) }

      it "returns false" do
        expect(processor.call).to be false
      end
    end
  end

  describe "#processing_task" do
    let(:processor) { described_class.new(valid_config) }
    let(:task) { valid_config["tasks"].first }
    let(:task_processor) { instance_double(BackupClient::Components::Tasks::Commands::Processor) }

    before do
      allow(BackupClient::Components::Tasks::Commands::Processor).to receive(:new)
        .and_return(task_processor)
      allow(task_processor).to receive(:call)
    end

    it "creates a task processor with correct parameters" do
      expect(BackupClient::Components::Tasks::Commands::Processor).to receive(:new)
        .with(task, config: valid_config)
        .and_return(task_processor)
      processor.send(:processing_task, task)
    end

    it "calls the task processor" do
      expect(task_processor).to receive(:call)
      processor.send(:processing_task, task)
    end
  end
end
