#!/bin/bash

source qm.variables
source lib/common.sh

#function to generate keyPair for node
function generateKeyPair(){
    echo -ne "\n" | constellation-node --generatekeys=${mNode} 1>>/dev/null

    echo -ne "\n" | constellation-node --generatekeys=${mNode}a 1>>/dev/null

    mv ${mNode}*.*  ${mNode}/node/keys/.

}

#function to create node initialization script
function createInitNodeScript(){
    cp lib/powerchain/init_template.sh ${mNode}/init.sh
    chmod +x ${mNode}/init.sh
}

#function to create start node script with --raft flag
function copyScripts(){
    NET_ID=$(awk -v min=10000 -v max=99999 -v freq=1 'BEGIN{srand(); for(i=0;i<freq;i++)print int(min+rand()*(max-min+1))}')
    
    cp lib/powerchain/start_powerchain_template.sh ${mNode}/node/start_${mNode}.sh
    chmod +x ${mNode}/node/start_${mNode}.sh

    cp lib/powerchain/start_template.sh ${mNode}/start.sh
    chmod +x ${mNode}/start.sh

    cp lib/powerchain/pre_start_check_template.sh ${mNode}/node/pre_start_check.sh
    START_CMD="start_${mNode}.sh"
    PATTERN="s/#start_cmd#/${START_CMD}/g"
    sed -i $PATTERN ${mNode}/node/pre_start_check.sh
    PATTERN="s/#nodename#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/pre_start_check.sh
    PATTERN="s/#netid#/${NET_ID}/g"
    sed -i $PATTERN ${mNode}/node/pre_start_check.sh
    chmod +x ${mNode}/node/pre_start_check.sh

    cp lib/common.sh ${mNode}/node/common.sh

    cp lib/powerchain/constellation_template.conf ${mNode}/node/${mNode}.conf

    cp lib/powerchain/tessera-migration.properties ${mNode}/node/qdata

    cp lib/powerchain/empty_h2.mv.db ${mNode}/node/qdata/${mNode}.mv.db

    cp lib/powerchain/migrate_to_tessera.sh ${mNode}/node
    PATTERN="s/#mNode#/${mNode}/g"
    sed -i $PATTERN ${mNode}/node/migrate_to_tessera.sh

}

#function to generate enode
function generateEnode(){
    if [[ -z "$pKey" ]]; then
        bootnode -genkey nodekey
    else 
        echo ${pKey} > nodekey
    fi  

    nodekey=$(cat nodekey)
    enode=$(bootnode -nodekey nodekey -writeaddress)
        
    cp nodekey ${mNode}/node/qdata/geth/.
    chmod o+r ${mNode}/node/qdata/geth/nodekey
    cp lib/powerchain/static-nodes_template.json ${mNode}/node/qdata/static-nodes.json
    PATTERN="s|#eNode#|${enode}|g"
    sed -i $PATTERN ${mNode}/node/qdata/static-nodes.json

    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){
    mAccountAddress="$(geth --datadir datadir --password lib/powerchain/passwords.txt account new 2>> /dev/null)"
    re="\{([^}]+)\}"
    if [[ $mAccountAddress =~ $re ]];
    then
        mAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    cp datadir/keystore/* ${mNode}/node/qdata/keystore/${mNode}key
    PATTERN="s|#mNodeAddress#|${mAccountAddress}|g"
    PATTERN1="s|#CHAIN_ID#|${NET_ID}|g"
    #BFT#
    mExtraData="$(istanbul extra encode --validators ${mAccountAddress} | cut -d " " -f 4)"
    mTimeStamp="$(istanbul setup | tail -n +2 | jq -r .timestamp)"
    PATTERN2="s|#mExtraData#|${mExtraData}|g"
    PATTERN3="s|#mTimeStamp#|${mTimeStamp}|g"
    #BFT#
    cat lib/powerchain/genesis_template.json >> ${mNode}/node/genesis.json
    sed -i $PATTERN ${mNode}/node/genesis.json
    sed -i $PATTERN1 ${mNode}/node/genesis.json
    sed -i $PATTERN2 ${mNode}/node/genesis.json
    sed -i $PATTERN3 ${mNode}/node/genesis.json
    rm -rf datadir
}

function importAccount(){
    echo ${pKey} > temp_key
    mAccountAddress="$(geth --datadir datadir --password lib/powerchain/passwords.txt account import temp_key 2>> /dev/null)"
    re="\{([^}]+)\}"
    if [[ $mAccountAddress =~ $re ]];
    then
        mAccountAddress="0x"${BASH_REMATCH[1]};
    fi
    cp datadir/keystore/* ${mNode}/node/qdata/keystore/${mNode}key
    PATTERN="s|#mNodeAddress#|${mAccountAddress}|g"
    PATTERN1="s|#CHAIN_ID#|${NET_ID}|g"
    #BFT#
    mExtraData="$(istanbul extra encode --validators ${mAccountAddress} | cut -d " " -f 4)"
    mTimeStamp="$(istanbul setup | tail -n +2 | jq -r .timestamp)"
    PATTERN2="s|#mExtraData#|${mExtraData}|g"
    PATTERN3="s|#mTimeStamp#|${mTimeStamp}|g"
    #BFT#
    cat lib/powerchain/genesis_template.json >> ${mNode}/node/genesis.json
    sed -i $PATTERN ${mNode}/node/genesis.json
    sed -i $PATTERN1 ${mNode}/node/genesis.json
    sed -i $PATTERN2 ${mNode}/node/genesis.json
    sed -i $PATTERN3 ${mNode}/node/genesis.json
    rm -rf datadir
    rm -rf temp_key
}

function cleanup(){
    rm -rf ${mNode}
    echo $mNode > .nodename
    mkdir -p ${mNode}/node/keys
    mkdir -p ${mNode}/node/contracts
    mkdir -p ${mNode}/node/qdata
    mkdir -p ${mNode}/node/qdata/{keystore,geth,logs}
    cp qm.variables $mNode
}

# execute init script
function executeInit(){
    cd ${mNode}
    ./init.sh
}


function readParameters() {
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -n|--name)
            mNode="$2"
            shift # past argument
            shift # past value                        
            ;;
            -pk|--privKey)
            pKey="$2"
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

    if [ -z "$mNode" ]; then
        return
    fi

    if [ -z "$mNode" ]; then
        help
    fi

    NON_INTERACTIVE=true
}

function main(){    

    readParameters $@

    if [ -z "$NON_INTERACTIVE" ]; then
        getInputWithDefault 'Please enter node name' "" mNode $ORANGE
        getInputWithDefault 'Please enter private key of this node' "" pKey $GREEN
    fi
        
    cleanup
    generateKeyPair
    createInitNodeScript
    copyScripts
    generateEnode

    if [[ -z "$NON_INTERACTIVE" && -z "$pKey" ]]; then
        createAccount
    else 
        importAccount
    fi
    
    executeInit   
}

main $@
