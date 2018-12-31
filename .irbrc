require 'irb/ext/save-history'
# History configuration
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"
unless defined?(reload!)
  $files = []
  def load!(file)
    $files << file
    load file
  end

  def reload!
    $files.each { |f| load f }
  end
end
