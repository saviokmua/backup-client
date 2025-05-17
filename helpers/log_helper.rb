# frozen_string_literal: true

module LogHelper
  def log(msg)
    puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}"
  end
end
