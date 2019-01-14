require 'logger'
module Moral
  class App
    def initialize
      @threads = []
    end

    def self.logger
      return @logger if @logger

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG # FIXME: log level by config
      @logger
    end

    def run!
      Signal.trap("INT") do
        Thread.new do
          Moral::App.logger.debug "SIGINT"
          Moral::Config.instance.balancers.each(&:remove!)
          Moral::Config.instance.die
          @threads.each(&:kill)
        end.join
        exit 130
      end

      # Check Cluster state

      @cfg = Moral::Config.instance
      if @cfg.heartbeat_config.enabled
        @cfg.heartbeat_nodes.each do |n|
          next if n.name == @cfg.heartbeat_config.me

          other_status = n.health_check.run!
          begin
            current_master = RestClient.get("http://#{n.name}:#{n.port}/master")
          rescue StandardError => ex
            current_master = "fail"
          end
          puts "CURRENT MASTER: #{current_master} " 
          hc = @cfg.heartbeat_config
          if hc.me == hc.primary
            if current_master != hc.me
              puts "TAKE IT"
              # i should  be master
              @cfg.stepup
            end
          else
            # i should not be master
            puts "i am slave"
            @cfg.die
          end
        end
      else
        @ipvs = Moral::IPVS.new
        @ipvs.update_table
      end

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
        api = Moral::RestAPI.go(@mutex, @ipvs)
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
