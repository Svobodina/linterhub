set -e

source bin/lh_utils.sh

log RUN "$@"

# Entry point
function main() {
    case $Mode in
        # Engine commands
        -b|build)    engine_build;;
        -a|analyze)  engine_analyze;;
        -s|export)   engine_export;;
        # Engine debug commands
        -r|run)      engine_run;;
        -e|exec)     engine_exec;;
        -d|destroy)  engine_destroy;;
        # Engine images
        -i|images)   engine_images;;
        -o|online)   engine_online;;
        -f|offline)  engine_offline;;
    esac
}

function parse_args() {
    while [[ $# -gt 1 ]] 
    do
        key="$1"
        case $key in
            --mode)      Mode="$2";;
            --dock)      EngineDock="$2";;
            --image)     EngineImage="$2";;
            --instance)  EngineInstance="$2";;
            --path)      Path="$2";;
            --output)    Output="$2";;
            --command)   Command="$2";;
            --workdir)   Workdir="$2";;
            --share)     Share="$2";;
            --prefix)    Prefix="$2";;
            --start)     Startup="$2";;
        esac
        shift
        shift
    done
}

# Engine functions
function engine_build()
{
    log INFO "Build linter dock"
    docker build --build-arg WORKDIR=$Workdir -t $EngineImage -f $EngineDock . 
}

function engine_analyze()
{
    log INFO "Run analysis"
    if [ ! "$Output" ];
        then docker run -i --rm --name $EngineInstance --volumes-from=$Share $EngineImage ${Command//[\"]}
        else docker run -i --rm --name $EngineInstance --volumes-from=$Share $EngineImage ${Command//[\"]} > "$Output"
    fi
}

function engine_export()
{
    log INFO "Save dock"
    mkdir -p images
    docker save $EngineImage | gzip -c
}

# Engine debug functions
function engine_run()
{
    elog INFO "Run linter dock"
    docker run -i -d --name $EngineInstance --volumes-from=$Share $EngineImage $Startup
}

function engine_exec()
{
    log INFO "Execute command in linter dock"
    docker exec -it $EngineInstance $Command
}

function engine_destroy()
{
    log INFO "Destroy linter dock"
    docker rm -f $EngineInstance
}

# Engine image functions
function engine_images()
{
    log INFO "Docker containers"
    docker images | grep $Prefix
}

function engine_online()
{
    log INFO "Docker online images"
    echo "docker search"
}

function engine_offline()
{
    log INFO "Docker offline images"
    ls -d dockers/alpine/*/ | cut -f3 -d'/'
}

parse_args "$@"
main "$@"
exit $?