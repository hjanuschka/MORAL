module Moral
  module HealthChecks
    class Events
      attr_accessor :node
      def rise!
        execute!(@rise) if @rise
      end
      def fall!
        execute!(@fall) if @fall
      end
      def execute!(a_cmd)
        Moral::App.logger.debug "Executing event:"
        a_cmd.each do | c |
          ruby!(c['ruby']) if c['ruby']
          shell!(c['shell']) if c['shell']
          clear!(c['clear']) if c['clear']
          exit!(c['exit']) if c['exit']
        end
        Moral::App.logger.debug "/Event Done"
      end
      def exit!(cmd)
        Moral::App.logger.debug "EXIT"
        # FIXME find way to exit all threads :o
      end
      def clear!(cmd)
        if cmd == "all"
        Moral::App.logger.debug "\t clear: Removing all"
          Moral::Config.instance.balancers.each do |b|
            b.remove!
          end
        end
        if cmd == "balancer"
        Moral::App.logger.debug "\t clear: Removing balancer"
          @node.balancer.remove!
        end
        if cmd == "node"
        Moral::App.logger.debug "\t clear: Removing Node"
          @node.remove!
        end
      end
      def shell!(cmd)
        Moral::App.logger.debug "\t shell #{cmd}"
        Moral::Misc.command(cmd)
      end
      def ruby!(cmd)
        Moral::App.logger.debug "\t ruby #{cmd}"
      end
      def initialize(rise: nil, fall: nil, node: nil)
        @rise = rise
        @fall = fall
        @node = node
      end
    end
  end
end
