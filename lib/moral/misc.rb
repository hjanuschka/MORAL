require 'open3'
module Moral
  class Misc
    def self.command(command)
      puts "Running command: #{command}"
      Open3.capture2("#{command} 2>&1")
      # yield(stdout_str, status)
    end

    def self.command_block_with_env(command, env = nil)
      puts "Running command: #{command}"
      puts "env: #{env.inspect}"
      stdout_str, status = Open3.capture2(env, "#{command} 2>&1")
      yield(stdout_str, status)
    end

    def self.command_block(command, _env = nil)
      puts "Running command: #{command}"
      stdout_str, status = Open3.capture2("#{command} 2>&1")
      yield(stdout_str, status)
    end
  end
end
