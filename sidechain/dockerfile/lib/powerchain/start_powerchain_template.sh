#!/bin/bash

function upcheck() {
    DOWN=true
    k=10
    while ${DOWN}; do
        sleep 1
        DOWN=false
        
        if [ ! -S "qdata/${NODE_NAME}.ipc" ]; then
            echo "Node is not yet listening on ${NODE_NAME}.ipc" >> qdata/gethLogs/${NODE_NAME}.log
            DOWN=true
        fi

        result=$(curl -s http://$CURRENT_NODE_IP:$C_PORT/upcheck)

        if [ ! "${result}" == "I'm up!" ]; then
            echo "Node is not yet listening on http" >> qdata/gethLogs/${NODE_NAME}.log
            DOWN=true
        fi
    
        k=$((k - 1))
        if [ ${k} -le 0 ]; then
            echo "Constellation/Tessera is taking a long time to start.  Look at the Constellation/Tessera logs for help diagnosing the problem." >> qdata/gethLogs/${NODE_NAME}.log
        fi
       
        sleep 5
    done
}

PK=$(<qdata/geth/nodekey)

ENABLED_API="admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul"
GETH_ARGS="--v5disc
           --datadir qdata 
           --rpccorsdomain '*' 
           --rpcport $R_PORT 
           --port $W_PORT 
           --ws 
           --wsaddr 0.0.0.0 
           --wsport $WS_PORT 
           --wsorigins '*' 
           --wsapi $ENABLED_API 
           --nat extip:$CURRENT_NODE_IP
           --istanbul.blockperiod 5 
           --syncmode full 
           --mine 
           --minerthreads 1 
           --networkid $NETID 
           --rpc 
           --rpcaddr 0.0.0.0 
           --rpcapi $ENABLED_API 
           --emitcheckpoints 
           --litaccvalidator.infuraurl $INFURA_URL 
           --litaccvalidator.contract $CONTRACT_ADDRESS 
           --litaccvalidator.chainid $CHAIN_ID" 

tessera="java -jar /tessera/tessera-app.jar"

echo "[*] Starting Constellation node" > qdata/constellationLogs/constellation_${NODE_NAME}.log
constellation-node ${NODE_NAME}.conf >> qdata/constellationLogs/constellation_${NODE_NAME}.log 2>&1 &

upcheck

echo "[*] Starting ${NODE_NAME} node" >> qdata/gethLogs/${NODE_NAME}.log
echo "[*] geth $GETH_ARGS">> qdata/gethLogs/${NODE_NAME}.log

PRIVATE_CONFIG=qdata/$NODE_NAME.ipc geth $GETH_ARGS 2>>qdata/gethLogs/${NODE_NAME}.log &

cd /root/powerchain-sidechain/
./start_nodemanager.sh -r $R_PORT -g $NODE_MANAGER_PORT -c $CHAIN_ID -m $MINING_FLAG -p $PK -I $INFURA_URL -C $CONTRACT_ADDRESS
