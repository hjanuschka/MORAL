require 'moral/version'

require 'moral/models/base'
require 'moral/models/balancer'
require 'moral/models/node'
require 'moral/models/docker_node'
require 'moral/models/health_check'

require 'moral/config'

require 'moral/services/ipvs'
require 'moral/misc'

require 'yaml'
require 'json'
require 'ostruct'
require 'pry'


# start threads

# TABLE CREATE
ipvs = Moral::IPVS.new

# Thread1
# WatchDog
#
#
# Thread2
#
# Docker Thread
#
# Thread3
#
# Sinatra

ipvs.run
