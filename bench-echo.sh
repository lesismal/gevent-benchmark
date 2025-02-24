#!/bin/bash

set -e

echo ""
echo "--- BENCH ECHO START ---"
echo ""

cd $(dirname "${BASH_SOURCE[0]}")
function cleanup {
    echo "--- BENCH ECHO DONE ---"
    kill -9 $(jobs -rp)
    wait $(jobs -rp) 2>/dev/null
}
trap cleanup EXIT

mkdir -p bin
$(pkill -9 net-echo-server || printf "")
$(pkill -9 evio-echo-server || printf "")
$(pkill -9 eviop-echo-server || printf "")
$(pkill -9 nbio-echo-server || printf "")
$(pkill -9 gev-echo-server || printf "")
$(pkill -9 gnet-echo-server || printf "")
$(pkill -9 gevent-echo-server || printf "")

function gobench {
    echo "--- $1 ---"
    if [ "$3" != "" ]; then
        go build -o $2 $3
    fi
    GOMAXPROCS=1 $2 --port $4 &
    sleep 1
    echo "*** 50 connections, 10 seconds, 6 byte packets"
    nl=$'\r\n'
    # 1k 5k 20k 30k
    tcpkali --workers 1 -c 100 -T 10s -m "PING{$nl}" 127.0.0.1:$4
    echo "--- DONE ---"
    echo ""
}

gobench "GO STDLIB" bin/net-echo-server net-echo-server/main.go 5001
gobench "EVIO" bin/evio-echo-server evio-echo-server/main.go 5002
gobench "EVIOP" bin/eviop-echo-server eviop-echo-server/main.go 5003
gobench "GEV" bin/gev-echo-server gev-echo-server/main.go 5004
gobench "NBIO" bin/nbio-echo-server nbio-echo-server/main.go 5005
gobench "GNET" bin/gnet-echo-server gnet-echo-server/main.go 5006
gobench "GEVENT" bin/gevent-echo-server gevent-echo-server/main.go 5007
