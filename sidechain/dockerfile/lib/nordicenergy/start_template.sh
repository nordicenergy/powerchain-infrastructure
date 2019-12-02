#!/bin/bash

source qm.variables
source node/common.sh

function readParameters() {
    
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -d|--detached)
            detached="true"
            shift # past argument
            shift # past value
            ;;          
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

}

# docker command to join th network 
function startNode(){

    docker kill $NODENAME 2> /dev/null && docker rm $NODENAME 2> /dev/null

    docker run $DOCKER_FLAG --rm --name $NODENAME \
           -v $(pwd):/home \
           -v $(pwd)/node/contracts:/root/powerchain/contracts \
           -w /home/node  \
           -p $RPC_PORT:$RPC_PORT \
           -p $WHISPER_PORT:$WHISPER_PORT \
           -p $WHISPER_PORT:$WHISPER_PORT/udp \
           -p $CONSTELLATION_PORT:$CONSTELLATION_PORT \
           -p $THIS_NODEMANAGER_PORT:$THIS_NODEMANAGER_PORT\
           -p $WS_PORT:$WS_PORT \
           -e NODENAME=$NODENAME \
           -e CURRENT_NODE_IP=$CURRENT_IP \
           -e R_PORT=$RPC_PORT \
           -e W_PORT=$WHISPER_PORT \
           -e C_PORT=$CONSTELLATION_PORT \
           -e NM_PORT=$THIS_NODEMANAGER_PORT \
           -e WS_PORT=$WS_PORT \
           -e NETID=$NETWORK_ID \
           -e POWERCHAIN_IP=$POWERCHAIN_IP \
           -e MC_PORT=$POWERCHAIN_CONSTELLATION_PORT \
           -e CHAIN_ID=$CHAIN_ID \
           -e INFURA_URL=$INFURA_URL \
           -e CONTRACT_ADDRESS=$CONTRACT_ADDRESS \
           -e MINING_FLAG=$MINING_FLAG \
           $dockerImage ./start_$NODENAME.sh
}

function main(){
    docker run -it --rm -v $(pwd):/home  -w /${PWD##*}/home  \
              $dockerImage node/pre_start_check.sh

    source setup.conf

    if [ -z $NETWORK_ID ]; then
        exit
    fi

    readParameters $@

    if [[ -z "$detached" ]]; then     
	    DOCKER_FLAG="-it"
    else
	    DOCKER_FLAG="-d"
    fi 		

    MINING_FLAG=false
    if [ -n $ROLE ] && [[ $ROLE == "validator" ]]; then
      MINING_FLAG=true
    fi

    startNode
}
main $@
