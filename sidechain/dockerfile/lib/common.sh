
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
PINK=$'\e[1;35m'
CYAN=$'\e[1;96m'
WHITE=$'\e[1;39m'
COLOR_END=$'\e[0m'

function getInputWithDefault() {
    local msg=$1
    local __defaultValue=$2
    local __resultvar=$3
    local __clr=$4
    
    if [ -z "$__clr" ]; then

        __clr=$RED

    fi

    if [ -z "$__defaultValue" ]; then

       read -p $__clr"$msg: "$COLOR_END __newValue
    else
        read -p $__clr"$msg""[Default:"$__defaultValue"]:"$COLOR_END __newValue
    fi
    
    
    if [ -z "$__newValue" ]; then

        __newValue=$__defaultValue

    fi

    eval $__resultvar="'$__newValue'"
}

function selectEthNetwork() {
  local msg=$1
  local __resultvar=$2
  local __clr=$3
  
  if [ -z "$__clr" ]; then
      __clr=$RED
  fi

  echo -e $__clr"$msg: [Enter for default -> Ropsten]\n" \
      $GREEN'1) Ropsten \n' \
      $PINK'2) Mainnet'
  printf $WHITE"option: "$COLOR_END
  
  read option
  # Default is Ropsten
  option=${option:-1}

  case $option in
  1)
    echo "1 selected"
    eval $__resultvar='ropsten';;
  2)
    echo "2 selected"
    eval $__resultvar='mainnet';;
  *)
    echo "Please enter a valid option"
    exit 1;;
	esac
}

function updateProperty() {
    local file=$1
    local key=$2
    local value=$3
  
    if grep -q $key= $file; then        
        sed -i "s/$key=.*/$key=$value/g" $file
    else
        echo "" >> $file
        echo $key=$value >> $file
    fi
    sed -i '/^$/d' $file
}

function displayProgress(){
    local __TOTAL=$1
    local __CURRENT=$2

    let __PER=$__CURRENT*100/$__TOTAL
    
    local __PROG=""

    local __j=0
    while : ; do  

        if [ $__j -lt $__PER ]; then
            __PROG+="\xE2\x96\x90"
        else
            __PROG+=" "
        fi

        if [ $__j -eq 100 ]; then
            break;
        fi
        let "__j+=2"
    done

    echo -ne ' ['${YELLOW}"${__PROG}"${COLOR_END}']'$GREEN'('$__PER'%)'${COLOR_END}'\r'

    if [ $__TOTAL -eq $__CURRENT ]; then
            echo ""
            break;
    fi

}

function help(){
    echo ""
    echo -e $WHITE'Usage ./setup.sh [COMMAND] [OPTIONS]'$COLOR_END
    echo ""
    echo "Utility to setup PowerChain Network"
    echo ""
    echo "Commands:"
    echo -e $GREEN'create'$COLOR_END    "           Create a new Node. The node hosts PowerChain sidechain, Constellation and Node Manager"
    echo -e $PINK'join as validator'$COLOR_END       "Create a node and Join as validator to existing PowerChain sidechain network"
    echo -e $BLUE'join'$COLOR_END     "             Create a node and Join to existing PowerChain sidechain network"
    echo ""
    echo "Options:"
    echo ""
    echo -e $GREEN'For create command:'$COLOR_END
    echo "  -n, --name              Name of the node to be created"
    echo "  --ip                    IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  -c, --constellation     Constellation port of this node"
    echo "  --nm                    Node Manager port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo "  -t, --tessera           Create node with Tessera Support (Optional)"
    echo "  -pk|--privKey           Private key of node (Optional)"
    echo "  -en|--ethnet            Ethereum network"
    echo "  -cid|--chainId          Chain ID in PowerChain Ethereum smart-contract to interact with"
    echo "NOTE if key is not provided, node keys will be generated"
    echo ""
    echo "E.g."
    echo "./setup.sh create -n powerchain --ip 10.0.2.87 -r 22000 -w 22001 -c 22002 --nm 22004 --ws 22005 --ethnet ropsten --chainId 0"
    echo ""
    echo -e $ORANGE'For join as validator command:'$COLOR_END
    echo "  -n, --name              Name of the node to be created"
    echo "  --oip                   IP address of the other node (IP of the existing node)"
    echo "  --onm                   Node Manager port of the other node"
    echo "  --tip                   IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  -c, --constellation     Constellation port of this node"
    echo "  --nm                    Node Manager port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo "  -t, --tessera           Create node with Tessera Support (Optional)"
    echo "  -pk|--privKey           Private key of node (Optional)"
    echo "  -en|--ethnet            Ethereum network"
    echo "  -cid|--chainId          Chain ID in Nordic Energy Ethereum smart-contract to interact with"
    echo "NOTE if key is not provided, node keys will be generated"
    echo ""
    echo "E.g."
    echo "./setup.sh join_as_validator -n nordicenergy1 --oip 10.0.2.87 --onm 22004 --tip 10.0.2.87 -r 23000 -w 23001 -c 23002 --nm 23004 --ws 23005 --ethnet ropsten --chainId 0"
    echo ""
    echo -e $BLUE'For join command:'$COLOR_END
    echo "  -n, --name              Name of the node to be created"
    echo "  --oip                   IP address of the other node (IP of the existing node)"
    echo "  --onm                   Node Manager port of the other node"
    echo "  --tip                   IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  -c, --constellation     Constellation port of this node"
    echo "  --nm                    Node Manager port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo "  -t, --tessera           Create node with Tessera Support (Optional)"
    echo "  -pk|--privKey           Private key of node (Optional)"
    echo "  -en|--ethnet            Ethereum network"
    echo "  -cid|--chainId          Chain ID in Nordic Energy Ethereum smart-contract to interact with"
    echo "NOTE if key is not provided, node keys will be generated"
    echo ""
    echo "E.g."
    echo "./setup.sh join -n nordicenergy1 --oip 10.0.2.87 --onm 22004 --tip 10.0.2.87 -r 23000 -w 23001 -c 23002 --nm 23004 --ws 23005  --ethnet ropsten --chainId 0"
    echo ""
    echo "-h, --help              Display this help and exit"

    exit
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}
