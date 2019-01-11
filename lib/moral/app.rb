require 'logger'
module Moral
  class App
    def initialize
      @threads = []
    end

    def self.logger
      return @logger if @logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG # FIXME log level by config
      @logger
    end
    def run!
      trap "SIGINT" do
        Moral::App.logger.debug "SIGINT"
        @threads.each(&:kill)
        exit 130
      end

      @ipvs = Moral::IPVS.new
      @ipvs.update_table
      # start threads
      #

      @mutex = Mutex.new
      @watchdog = Thread.new do
        Moral::WatchDog.new(@mutex, @ipvs).run!
      end

      @docker = Thread.new do
        Moral::App.logger.debug("FIXME: docker thread")
        Moral::App.logger.debug 'FIXME DOCKER'
      end

      @sinatra = Thread.new do
        #api = Moral::RestAPI.go(@mutex, @ipvs)
      end

      @heartbeat = Thread.new do
        Moral::HeartBeat.new(@mutex, @ipvs).run!
      end

      @threads << @watchdog
      @threads << @docker
      @threads << @sinatra

      # wait for all threads
      @threads.each(&:join)

     Moral::App.logger.debug 'END'
    end
  end
end
