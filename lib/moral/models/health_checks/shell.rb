module Moral
  class ShellHealthCheck < HealthCheck
    def run!
      env = {"MORAL_ADDRESS" => @node.address, "MORAL_PORT" => @node.port.to_s, "MORAL_BALANCER" => @node.balancer.service_address}
      Moral::Misc.command_block_with_env(@definition['command'], env) do | stdout, status |
        if status == 0
          return :good
        end
        return :bad
      end
      return :bad
    end
  end
end
