[blockscout]: https://github.com/blockscout/blockscout.git

This is a docker-compose version of [blockscout] block explorer, tailed to work with local ganache chain.

## Requirements
* `docker`
* `docker-compose`
* `ganache-cli`

## Set up steps
*  Run local `ganache` node on `0.0.0.0` address
* `docker-compose build`
* Modify, if need, the `.env` file. The `BLOCKSCOUT_VERSION` refers to [blockscout] tag version
* `GPORT=<ganache-cli--port> docker-compose up -d`, for brownie ide `GPORT=8545` is set by default

## Troubles
In case of troubles with connection to db try to remove `dbvolume` from host system or from `docker-compose.yaml` file
