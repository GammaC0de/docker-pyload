#!/bin/sh
set -euf
CONTAINER=$(docker run -d -v $PWD/test/downloads:/opt/pyload/Downloads -P pyload)
RET=0
URL=$1

pyLoadCli(){
  docker exec -i $CONTAINER /opt/pyload/pyLoadCli.py "$@"
}

trap 'docker logs $CONTAINER;docker stop $CONTAINER;exit $RET' INT TERM EXIT

sleep 5

log(){
  echo "$(date +%H:%M:%S) " "$@"
}

log "Sleeping ... "
log "Adding: $URL"
pyLoadCli add "Test" "$URL"
while true;do
  data=$(pyLoadCli queue)
  case "$data" in
    *"queued"*"XDCC"*)
      log "Queued"
      ;;
    *"starting"*"XDCC"*)
      log "Starting"
      ;;
    *"connect"*"XDCC"*)
      log "Connecting"
      ;;
    *"waiting"*"XDCC"*)
      log "Waiting"
      ;;
    *"downloading"*"XDCC"*)
      log $(pyLoadCli status | grep Downloading)
      ;;
    *"failed"*"XDCC"*)
      log "Download Failed!"
      RET=1
      break
      ;;
    *"finished"*"XDCC"*)
      log "Download finished"
      RET=0
      break
      ;;
    *)
      log "something weird happened:"
      log "$data"
      pyLoadCli status
      RET=1
      break
    ;;
  esac
  sleep 5
done
