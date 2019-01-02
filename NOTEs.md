###### MorAl
Optix for CLI grouping
sinatra web server
react ui
  parcel bundler

foreman process manager (parcel + sinatra)

IPVS on steriods


  - Configuration:
    - YAML based
  - Run, in container or not
  - auto discover of hosts via docker api
    - https://github.com/swipely/docker-api
  - health checks (seperate thread)
   - TCP
   - HTTP/https
   - custom via SH script



# IPVS commands
## Add service
  ipvsadm -A -t  192.168.0.1:8080 -s rr

## add real server
  ipvsadm -a -t 192.168.0.1:8080 -r 192.168.0.4:8080 -m
  


ruby objects
  App
    Rest-API (sinatra)
    GET:
      /v1/balancers
        /v1/balancers/balancer1/nodes
          /v1/balancers/balancer1/nodes/moritz
    WatchDog
      TCP
      HTTP/S
      Plugin
    IPVS
      Service
      Node



config:
##### simple

balancer1:
  routing: dr
  scheduler: rr
  address: 192.168.239.6
  port: 8080
  nodes:
    alisa:
      type: node
      weight: 1
      address: 192.168.239.1
      port: 80
      health:
        window:
          interval: 10s
          dead_on: 1
          back_on: 1
        type: tcp
        definition:
          timeout: 2
    moritz:
      type: node
      weight: 1
      address: 192.168.239.2
      port: 80
      health:
        type: http
         window:
          interval: 10s
          dead_on: 1
          back_on: 1
        definition:
          endpoint: /v1/health
          timeout: 2
          expectet
            content: "some string"
            status: 200

    docker_container:
      type: docker
      weight: 1
      address: 192.168.239.2
      port: 80
      docker:
        name: ^frontend^
        port: 8088
        dynamic: true
      health:
        type: http
         window:
          interval: 10s
          dead_on: 1
          back_on: 1
        definition:
          endpoint: /v1/health
          timeout: 2
          expectet
            content: "some string"
            status: 200



  
