module Moral
  class HeartBeat
    def initialize(mutex, ipvs)
      @mutex = mutex
      @ipvs = ipvs
    end

    def run!
      # check if i am primary
      # get role from other node
      # takeover role
      # takedown opposite
      loop do
        checks = []
        Moral::Config.instance.heartbeat_nodes.each do |node|
          next if node.name == Moral::Config.instance.heartbeat_config.me

          checks << node
        end

        checks.each do |node|
          c = node.health_check
          last_run_diff = (Time.now - c.last_check).to_i
          next if last_run_diff.to_i < c.interval.to_i

          status =  c.run!
          @mutex.synchronize do
            c.state = status
            c.last_check = Time.now
            if c.last_state != status
              c.last_state = status
              c.retain_count = 1
              c.state_changed = true
            else
              c.retain_count += 1
            end
            if c.last_state == :good && c.retain_count == c.back_on && c.state_changed
              # FIXME: all is good takeover
              Moral::App.logger.debug("HEARTBEAT: GOOD")
              # takeover, and takedown other
              cfg = Moral::Config.instance
              hc = cfg.heartbeat_config
              if hc.primary != cfg.heartbeat_master
                cfg.die
                c.events.fall!
              end
            end

            if c.last_state == :bad && c.retain_count == c.back_on && c.state_changed
              # FIXME: failed
              # self-destruct + handover
              Moral::App.logger.debug("HEARTBEAT: fail!")
              # other node is dead
              # i am not master, i should not be, but i have to -> takeover
              hc = Moral::Config.instance.heartbeat_config
              cfg = Moral::Config.instance
              if hc.me != cfg.heartbeat_master
                puts "STEPUP"
                cfg.stepup
                c.events.rise!
              end
            end
          end
        end

        sleep 1
      end
    end
  end
end
