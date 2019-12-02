#!/bin/bash

source node/common.sh

function checkResponse(){
    rejected="Access denied"
    timeout="Response Timed Out"
    internalError="Internal error"
    
    response=$1
    if [ "$response" = "$rejected" ]
    then
        echo "Request to Join Network was rejected. Probale cause: You did not vest (validators) or deposit (non-validators). Program exiting"
        exit
    elif [ "$response" = "$timeout" ]
    then
        echo "Waited too long for approval from Master node. Please try later. Program exiting"
        exit
    elif [ "$response" = "$internalError" ]
    then
        echo "Something went wrong on the Master node. Please try later. Program exiting"
        exit    
    elif [ "$response" = "" ]
    then
        echo "Unknown Error. Please check log. Program exiting"
        exit
    fi
}

# Function to send post call to go endpoint joinNode 
function updateNmcAddress(){
    url=http://${POWERCHAIN_IP}:${MAIN_NODEMANAGER_PORT}/nmcAddress
    echo -e $CYAN'Network Manager address Request sent to '$url'.'$COLOR_END
 
    response=$(curl -s -X POST \
    --max-time 310 ${url} \
    -H "content-type: application/json" \
    -d '{
       "acc-pub-key":"'${ACC_PUBKEY}'"
    }')     
    checkResponse "$response"

    contractAdd=$(echo "$response" | jq -r '.nmcAddress')
    updateProperty setup.conf CONTRACT_ADD $contractAdd
}

function requestEnode(){
    urlG=http://${POWERCHAIN_IP}:${MAIN_NODEMANAGER_PORT}/peer

    echo -e $CYAN'\nEnode Request sent to '$urlG'.'$COLOR_END

    response=$(curl -s --max-time 310 ${urlG})
    checkResponse "$response"

    enode=$(echo $response | jq -r '.connectionInfo.enode')
    PATTERN="s|#POWERCHAIN_ENODE#|${enode}|g"
    sed -i $PATTERN node/qdata/static-nodes.json 

    node_chain_id=$(echo $response | jq -r '.chainId')

    if [ $node_chain_id != ${CHAIN_ID} ]; then
        echo -e $RED'\nYou are trying to connect to a network with different chain id '$node_chain_id' !'$COLOR_END
        exit 1;
    fi
}

# Function to send post call to java endpoint getGenesis 
function requestGenesis(){
    urlG=http://${POWERCHAIN_IP}:${MAIN_NODEMANAGER_PORT}/genesis

    echo -e $CYAN'Join Request sent to '$urlG'.'$COLOR_END

    response=$(curl -s -X POST \
    --max-time 310 ${urlG} \
    -H "content-type: application/json" \
    -d '{
       "enode-id":"'${enode}'",
       "ip-address":"'${CURRENT_IP}'",
       "nodename":"'${NODENAME}'",
       "acc-pub-key":"'${ACC_PUBKEY}'",
       "chain-id":"'${CHAIN_ID}'",
       "role":"'${ROLE}'"
    }')
    checkResponse "$response"

    echo $response > input1.json
	declare -A replyMap
	while IFS="=" read -r key value
	do
    	replyMap[$key]="$value"
	done < <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" input1.json)

    POWERCHAIN_CONSTELLATION_PORT=${replyMap[contstellation-port]}
   
	echo 'POWERCHAIN_CONSTELLATION_PORT='$POWERCHAIN_CONSTELLATION_PORT >>  setup.conf
	echo 'NETWORK_ID='${replyMap[netID]} >>  setup.conf
	echo ${replyMap[genesis]}  > node/genesis.json

    rm -f input1.json
}

function generateConstellationConf() {
    PATTERN1="s/#CURRENT_IP#/${CURRENT_IP}/g"
    PATTERN2="s/#C_PORT#/$CONSTELLATION_PORT/g"
    PATTERN3="s/#mNode#/$NODENAME/g"
    PATTERN4="s/#POWERCHAIN_IP#/$POWERCHAIN_IP/g"
    PATTERN5="s/#POWERCHAIN_CONSTELLATION_PORT#/$POWERCHAIN_CONSTELLATION_PORT/g"

    sed -i "$PATTERN1" node/$NODENAME.conf
    sed -i "$PATTERN2" node/$NODENAME.conf
    sed -i "$PATTERN3" node/$NODENAME.conf
    sed -i "$PATTERN4" node/$NODENAME.conf
    sed -i "$PATTERN5" node/$NODENAME.conf
}

# execute init script
function executeInit(){
    PATTERN="s/#networkId#/${netvalue}/g"
    sed -i $PATTERN node/start_${NODENAME}.sh
        
    ./init.sh
}

function migrateToTessera() {
    
    pushd node
    . ./migrate_to_tessera.sh >> /dev/null 2>&1
    popd
}

function main(){    

    source setup.conf
    
    if [ -z $NETWORK_ID ]; then
        enode=$(cat node/enode.txt)
        requestEnode
        requestGenesis
        executeInit
        updateNmcAddress
        generateConstellationConf
        
        if [ ! -z $TESSERA ]; then
            migrateToTessera            
        fi

        publickey=$(cat node/keys/$NODENAME.pub)
        echo 'PUBKEY='$publickey >> setup.conf

        uiUrl="http://localhost:"$THIS_NODEMANAGER_PORT"/"

        echo -e '****************************************************************************************************************'

        echo -e '\e[1;32mSuccessfully created and started \e[0m'$NODENAME
        echo -e '\e[1;32mConnected to the network with chainId \e[0m'$CHAIN_ID
        echo -e '\e[1;32mYou can send transactions to \e[0m'$CURRENT_IP:$RPC_PORT
        echo -e '\e[1;32mFor private transactions, use \e[0m'$publickey
        echo -e '\e[1;32mFor accessing Lition Maker UI, please open the following from a web browser \e[0m'$uiUrl
        echo -e '\e[1;32mTo join this node from a different host, please run PowerChain sidechain and choose option to run Join Network\e[0m'
        echo -e '\e[1;32mWhen asked, enter \e[0m'$CURRENT_IP '\e[1;32mfor Existing Node IP and \e[0m'$THIS_NODEMANAGER_PORT '\e[1;32mfor Node Manager port\e[0m'

        echo -e '****************************************************************************************************************'

    fi    

}
main
