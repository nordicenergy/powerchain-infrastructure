#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source qm.variables
source lib/common.sh

function banner() {
	printf $CYAN'  _    '$RED'   __      __\n' 
	printf $CYAN' | |    '$RED' |  \    /  |  \n'
	printf $CYAN' | |     '$RED'|   \  /   |  \n'
	printf $CYAN' | |     '$RED'|    \/    |  \n'
	printf $CYAN' | |     '$RED'| |\    /| |  \n'
	printf $CYAN' | |     '$RED'| | \  / | |  \n'
	printf $CYAN' | |_____'$RED'| |  \/  | |  \n'
	printf $CYAN' |_________|'$RED'      |_|  '

	local __version=$(egrep -Eo "[0-9].*" <<< $dockerImage)
	    
	IFS='_'; arrIN=($__version); unset IFS;

	echo -e $GREEN'Version '${arrIN[1]}' Built on PowerChain '${arrIN[0]}'\n'
}

function readParameters() {
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            create)
            option="1"
            shift # past argument
            ;;
            join_as_validator)
            option="2"
            shift # past argument
            ;;
			join)
            option="3"
            shift # past argument
            ;;
            -h|--help)
            help

            ;;
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

	if [[ ! -z $option && $option -lt 1 || $option -gt 3 ]]; then
		help
	fi

	if [ ! -z $option ]; then
		NON_INTERACTIVE=true
	fi

}

function main() {

	banner
	readParameters $@

	if [ -z "$NON_INTERACTIVE" ]; then
		flagmain=true
		echo -e $YELLOW'Please select an option: \n' \
				$GREEN'1) Create Network \n' \
				$PINK'2) Join Network as a validator\n' \
				$BLUE'3) Join Network\n' \
				$RED'4) Exit'

		printf $WHITE'option: '$COLOR_END

		read option
	fi

	case $option in
		1)
			lib/create_network.sh $@;;
		2)
			lib/join_network.sh --validator $@;;
		3)
			lib/join_network.sh $@;;
		4)
			flagmain=false	;;
		*)
			echo "Please enter a valid option"	;;
	esac
}

main $@