require 'open3'
module Moral
  class Misc
    def self.command(command)
      puts "Running command: #{command}"
      Open3.capture2("#{command} 2>&1")
      # yield(stdout_str, status)
    end

    def self.command_block(command)
      puts "Running command: #{command}"
      stdout_str, status = Open3.capture2("#{command} 2>&1")
      yield(stdout_str, status)
    end
  end
end
