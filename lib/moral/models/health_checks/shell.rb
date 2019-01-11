module Moral
  class ShellHealthCheck < HealthCheck
    def run!
      env = { 'MORAL_ADDRESS' => @node.address, 'MORAL_PORT' => @node.port.to_s, 'MORAL_BALANCER' => @node.balancer.service_address }
      Moral::Misc.command_block_with_env(@definition['command'], env) do |_stdout, status|
        return :good if status == 0

        return :bad
      end
      :bad
    end
  end
end
