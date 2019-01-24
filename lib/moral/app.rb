require 'logger'
require 'terminal-table'
require 'pastel'
module Moral
  class App
    def initialize
      @threads = []
    end

    def self.logger
      return @logger if @logger

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG # FIXME: log level by config
      @logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
        "[#{date_format}] #{severity}: #{msg}\n"
      end
      @logger
    end

    def log_table(table)
      table.to_s.split("\n").each { |l| Moral::App.logger.debug l }
    end

    def run!
      # Moral::App.logger.debug
      #

      # exit

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
          if other_status == :bad
            # opposite_failed = true
          end
          begin
            current_master = RestClient.get("http://#{n.name}:#{n.port}/master")
          rescue StandardError
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

      pastel = Pastel.new
      rows = []
      @cfg.balancers.each do |balancer|
        rows << [balancer.name, "", balancer.service_address, "UP", "STATS"]
        balancer.nodes.each do |node|
          rows << ["", node.name, node.server_address, "UP", "STATS"]
        end
      end

      table = Terminal::Table.new title: pastel.green("Overview"), headings: ['Balancer', 'Node', 'Address', 'State', 'Stats'], rows: rows, style: { width: 80 }
      log_table table

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
        Moral::RestAPI.go(@mutex, @ipvs)
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
