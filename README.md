This is a docker-compose version of [blockscout](https://github.com/blockscout/blockscout.git) block explorer, tailed to work with local ganache chain.

## Requirements
* `docker`
* `docker-compose`
* `ganache-cli`

## Set up steps
*  Run local `ganache` node on `0.0.0.0` address
* `docker-compose build`
* `GPORT=<ganache-cli--port> docker-compose up -d`, for brownie ide `GPORT=8545` by default
