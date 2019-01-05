module Moral
  class WatchDog
    def initialize(mutex, ipvs)
      @mutex = mutex
      @ipvs = ipvs
    end

    def run!
      loop do
        checks = []
        Moral::Config.instance.balancers.each do |balancer|
          balancer.nodes.each do |node|
            checks << node
          end
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
              Moral::App.logger.debug "bringing up: #{node.server_address}"
              node.rise!
            end

            if c.last_state == :bad && c.retain_count == c.back_on && c.state_changed
              Moral::App.logger.debug "bringing down: #{node.server_address}"
              node.fall!
            end
          end
        end

        sleep 1
      end
    end
  end
end
