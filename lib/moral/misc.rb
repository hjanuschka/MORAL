require 'open3'
module Moral
  class Misc
    def self.command(command)
      Moral::App.logger.debug "Running command: #{command}"
      Open3.capture2("#{command} 2>&1")
      # yield(stdout_str, status)
    end

    def self.command_block_with_env(command, env = nil)
      Moral::App.logger.debug "Running command: #{command}"
      Moral::App.logger.debug "env: #{env.inspect}"
      stdout_str, status = Open3.capture2(env, "#{command} 2>&1")
      yield(stdout_str, status)
    end

    def self.command_block(command, _env = nil)
      Moral::App.logger.debug "Running command: #{command}"
      stdout_str, status = Open3.capture2("#{command} 2>&1")
      yield(stdout_str, status)
    end
  end
end
