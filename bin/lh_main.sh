#!/bin/bash
# Disable "set -e" because some linters returns non 0 result

source bin/lh_utils.sh

log RUN "$@"

# Constants
Version="0.5"
Prefix="rm"
Start="/bin/sh"
Workdir="/shared"

# Scripts
Engine="bin/lh_engine.sh"
Storage="bin/lh_storage.sh"
Check="bin/lh_check.sh"

main() {
    # Mode
    if [ -z "$Mode" ]; then
        Mode=$1
    fi
	if [ -n "$Env" ]; then
	log INFO "Configure environment"
        eval $(docker-machine.exe env --shell sh)
		# Do it once per instance
		Env=
	fi
    case $Mode in
        # Storage commands
        -sb|storage:build)    sh $Storage \
                                --mode build \
                                --instance $Volume \
                                --dockshare $DockShare \
                                --hostshare $HostShare \
                                --path "$Path" \
                              ;;
        -sd|storage:destroy)  sh $Storage \
                                --mode destroy \
                                --instance $Volume \
                                --dockshare $DockShare \
                                --hostshare $HostShare \
                              ;;
        # Engine commands
        -eb|engine:build)     sh $Engine \
                                --mode build \
                                --image $Image \
                                --dock $Dock \
                                --workdir "$Workdir" \
                              ;;
        -ea|engine:analyze)   sh $Engine \
                                --mode analyze \
                                --image $Image \
                                --instance $Instance \
                                --share $Volume \
                                --command "$Command" \
                                --output "$Output" \
                              ;;
        -es|engine:export)    sh $Engine \
                                --mode export \
                                --image $Image \
                              ;;
        # Engine image commands
        -ei|engine:images)    sh $Engine \
                                --mode images \
                                --prefix $Prefix \
                              ;;
        -eo|engine:online)    sh $Engine \
                                --mode online \
                              ;;
        -ef|engine:offline)   sh $Engine \
                                --mode offline \
                              ;;
        # Engine debug commands
        -er|engine:run)       sh $Engine \
                                --mode run \
                                --image $Image \
                                --instance $Instance \
                                --share $Volume \
                                --start $Start \
                              ;;
        -ee|engine:exec)      sh $Engine \
                                --mode exec \
                                --instance $Instance \
                                --command "$Command" \
                              ;;
        -ed|engine:destroy)   sh $Engine \
                                --mode destroy \
                                --instance $Instance \
                              ;;
        # General commands
        -a|analyze)           analyze;;
        -c|check)             sh $Check;;
        -v|--version|version) echo $Version;;
        -h|--help|help|?|-?)  cat docs/usage.txt;;
        *)                    log ERROR "Unknown command. Try '$0 -help'";;
    esac
}

function parse_args() {
    # VM
    Volume="$Prefix-storage-instance"
    HostShare="HOST_SHARE"
    DockShare="/DOCKER_SHARE"
    while [[ $# -gt 1 ]] 
    do
        key="$1"
        case $key in
            --mode)      Mode="$2";;
            --name)      Name="$2"
                         Dock="dockers/alpine/$Name/Dockerfile"
                         Image="$Prefix-$Name-image"
                         Instance="$Prefix-$Name-instance"
                         ;;
            --command)   Command="$2";;
            --start)     Start="$2";;
            --share)     Share="$2";;
            --output)    Output="$2";;
            --workdir)   Workdir="$2";;
            --path)      Path="$2";;
            --clean)     Clean="true";;
            --session)   Session="true";;
			--env)       Env="true";;
            *)           log ERROR "Unknown command $1"
        esac
        shift
        shift
    done
}

# General functions
function analyze()
{
    if [ -n "$Session" ]; then
        # Storage session
        Session=$RANDOM
        # Not cross platform - Session=$(date +%s|md5|base64|head -c 8)
        Volume="$Prefix-storage-instance-$Session"
        HostShare="HOST_SHARE_$Session"
        DockShare="/DOCKER_SHARE_$Session"
    fi
    if [ -n "$Clean" ] || [ -n "$Session" ] ; then
        # Storage build
        Mode="storage:build"
        main
    fi
    # Linters
    IFS='+' read -ra linters <<< "$Name"
    for linterPart in "${linters[@]}"; do
        IFS=':' read -ra linter <<< "$linterPart"
        # Linter session
        Name=${linter[0]}
        Dock="dockers/alpine/$Name/Dockerfile"
        Image="$Prefix-$Name-image"
        Instance="$Prefix-$Name-instance-$Session"
        if [ -n "$Clean" ]; then
            # Linter build
            Mode="engine:build"
            main
        fi
        # Linter analyze
        Command="\"${linter[1]}"\"
        Output="${linter[2]}"
        echo "COM: $Command"
        Mode="engine:analyze"
        main
    done
    if [ -n "$Clean" ] || [ -n "$Session" ]; then
        # Storage destroy
        Mode="storage:destroy"
        main
    fi
}

parse_args "$@"
main "$@"
exit $?