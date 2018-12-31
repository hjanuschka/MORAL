require 'moral/version'
require 'moral/ipvs'
require 'yaml'
require 'pry'

module Moral
  # Your code goes here...
  # DEFAULT ENVS
  ENV['MORAL_CONFIG'] ||= 'moral.yml'
  ### LOAD YAML
  cfg = YAML.load_file(ENV['MORAL_CONFIG'])

  cfg['balancers'].each do |balancer|
    name = balancer.first
    bcfg = balancer.last

    service_def = "#{bcfg['address']}:#{bcfg['port']}"
    if svc = IPVS.service?(service_def)
      puts 'has service'
      puts 'check nodes'
      svc.nodes.each do |node|
        # Check if node is still in bcfg['nodes']
        # if not, remove it
        found = false
        bcfg['nodes'].each_pair do |_node_name, node_config|
          next if node_config['active'] == false
          if node.remote_address == "#{node_config['address']}:#{node_config['port']}"
            found = true
            break
          end
        end
        node.remove! unless found
      end
      bcfg['nodes'].each_pair do |_node_name, node_config|
        next if node_config['active'] == false
        # check if bcfg['nodes'] has new one's
        # add them if not
        found = false
        svc.nodes.each do |node|
          if node.remote_address == "#{node_config['address']}:#{node_config['port']}"
            found = true
            break
          end
        end
        unless found
          nn = svc.add_node(parameters: { 'RemoteAddress:Port' => "#{node_config['address']}:#{node_config['port']}", 'Weight' => node_config['weight'], 'Forward' => node_config['routing'] })
          nn.create!
        end
      end
    else
      # Create Service
      puts 'create service'
      svc = IPVSService.new(parameters: { 'Prot' => bcfg['protocol'], 'LocalAddress:Port' => service_def, 'Scheduler' => bcfg['scheduler'] })
      puts 'create nodes'
      bcfg['nodes'].each_pair do |_node_name, node_config|
        next if node_config['active'] == false
        next unless node_config['type'] == 'node' # FIXME later docker
        svc.add_node(parameters: { 'RemoteAddress:Port' => "#{node_config['address']}:#{node_config['port']}", 'Weight' => node_config['weight'], 'Forward' => node_config['routing'] })
      end
      svc.create!
    end
  end
end
