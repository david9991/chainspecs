if [ -z $1 ]; then
    echo 'Node name is required!'
    exit 1
fi

CHAINDATA_ROOT_DIR=$PWD

mkdir -p $CHAINDATA_ROOT_DIR/chain-data $CHAINDATA_ROOT_DIR/keystore $CHAINDATA_ROOT_DIR/relaychain-data $CHAINDATA_ROOT_DIR/relaychain-keystore

curl --location -o $CHAINDATA_ROOT_DIR/chain-data/chainspec.json https://github.com/david9991/chainspecs/raw/main/plcc-parachain-chainspec.json
curl --location -o $CHAINDATA_ROOT_DIR/relaychain-data/chainspec.json https://github.com/david9991/chainspecs/raw/main/plcc-relaychain-chainspec.json


NODE_KEY=`docker run -it --rm parity/polkadot-parachain key generate-node-key|tail -n1`

COLLECTOR_KEY=`docker run --rm \
-v $CHAINDATA_ROOT_DIR/chain-data:/chain-data \
-v $CHAINDATA_ROOT_DIR/keystore:/keystore \
-v $CHAINDATA_ROOT_DIR/relaychain-data:/relaychain-data \
-v $CHAINDATA_ROOT_DIR/relaychain-keystore:/relaychain-keystore \
--name=rococo-key \
parity/polkadot-parachain key generate`

TRIMMED_KEY=`echo "$COLLECTOR_KEY"|head -n1|sed 's/Secret phrase:       //'`

echo "$COLLECTOR_KEY"

docker run --rm \
-v $CHAINDATA_ROOT_DIR/chain-data:/chain-data \
-v $CHAINDATA_ROOT_DIR/keystore:/keystore \
-v $CHAINDATA_ROOT_DIR/relaychain-data:/relaychain-data \
-v $CHAINDATA_ROOT_DIR/relaychain-keystore:/relaychain-keystore \
--name=rococo-key \
parity/polkadot-parachain key insert --keystore-path /keystore \
--key-type aura --scheme sr25519 \
--suri "$TRIMMED_KEY"

echo -n $NODE_KEY > $CHAINDATA_ROOT_DIR/keystore/node-key

docker run -d --restart=always \
-v $CHAINDATA_ROOT_DIR/chain-data:/chain-data \
-v $CHAINDATA_ROOT_DIR/keystore:/keystore \
-v $CHAINDATA_ROOT_DIR/relaychain-data:/relaychain-data \
-v $CHAINDATA_ROOT_DIR/relaychain-keystore:/relaychain-keystore \
--name=$1 \
-p 9944:9944 \
-p 30333:30333 \
-p 30334:30334 \
parity/polkadot-parachain \
--name=$1 \
--base-path=/chain-data --keystore-path=/keystore \
--chain=/chain-data/chainspec.json --database=rocksdb \
--state-pruning=archive --collator --prometheus-external \
--prometheus-port 9615 --unsafe-rpc-external \
--rpc-port=9944 --rpc-cors=all --listen-addr=/ip4/0.0.0.0/tcp/30334 \
--node-key-file=/keystore/node-key --telemetry-url="wss://subtele.k.pocograph.com/submit/ 0" \
--bootnodes /dns/ho6.tj.pocograph.com/tcp/30335/p2p/12D3KooWL6TH6Saxvqzd1i6ejEFssKdzqvmST7F6WzUM3T3X5zGB \
--bootnodes /dns/ho6.tj.pocograph.com/tcp/30336/p2p/12D3KooWRicSHG2K8LruHBZ4K8EAE2YfLRQQURB31SwgnYNHguAc \
-- \
--chain=/relaychain-data/chainspec.json --name=$1 --base-path=/relaychain-data \
--keystore-path=/relaychain-keystore --database=rocksdb --state-pruning=1000 \
--telemetry-url="wss://subtele.k.pocograph.com/submit/ 0" \
--bootnodes /dns/ho6.tj.pocograph.com/tcp/30333/p2p/12D3KooWFMZB7E5Sn4tWZjACLFJuQp6dAV6Qx2RVgexngA5Ecdmi \
--bootnodes /dns/ho6.tj.pocograph.com/tcp/30334/p2p/12D3KooWDZb2JUuQ4hM1ynH3EQHqTZWk8bbHMpoymRhVUNPuZWaL