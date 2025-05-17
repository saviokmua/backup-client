# frozen_string_literal: true

# For Windows 7 please use ruby 2.4.X

CONFIG_FILE = 'config.yml'

require 'yaml'
require 'net/ftp'
require 'fileutils'
require 'time'
require 'byebug'
require './helpers/log_helper'
require './helpers/ftp_helper'
Dir.glob('components/**/*.rb').sort.each do |file|
  require_relative file
end
require './backup_client'

config ||= YAML.load_file(CONFIG_FILE)
command = BackupClient.new(config)
command.call
