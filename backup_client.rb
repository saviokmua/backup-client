# frozen_string_literal: true

class BackupClient
  include ::LogHelper

  def initialize(config)
    @config = config
    @tasks = config['tasks']
    # @providers = config['providers']
  end

  def call
    tasks.each { |task| processing_task(task) }
  end

  private

  attr_reader :tasks, :config

  def processing_task(task)
    ::Tasks::Commands::Processor.new(task, config: config).call
  end
end
