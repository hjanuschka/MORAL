module Moral
  class App
    def initialize
      @threads = []
    end

    def run!
      @ipvs = Moral::IPVS.new
      @ipvs.update_table
      # start threads
      #

      @mutex = Mutex.new
      @watchdog = Thread.new do
        Moral::WatchDog.new(@mutex, @ipvs).run!
      end

      @docker = Thread.new do
        puts 'FIXME DOCKER'
      end

      @sinatra = Thread.new do
        api = Moral::RestAPI.go(@mutex, @ipvs)
      end

      @threads << @watchdog
      @threads << @docker
      @threads << @sinatra

      # wait for all threads
      @threads.each(&:join)
      puts 'END'
    end
  end
end
