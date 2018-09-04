#!/usr/bin/env bash

STREAM_SERVER_COUNT=10
LOAD_SERVER_COUNT=10
ZOOKEEPER_SERVER_COUNT=3
KAFKA_SERVER_COUNT=5
SSH_USER="root"

CONTENT_TYPE="Content-Type: application/json"
AUTH="Authorization: Bearer 1b1744b1be9611fdc37b3acf7306f4b1e5116c42480ae6c20371d3ec7d6e39fb"



function runCommandStreamServers(){
    counter=1
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ${SSH_USER}@stream-node-0${counter} $1
        else
            nohup ssh ${SSH_USER}@stream-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandMasterStreamServers(){
    if [ "$2" != "nohup" ]; then
        ssh ${SSH_USER}@stream-node-01 $1
    else
        nohup ssh ${SSH_USER}@stream-node-01 $1 &
    fi
}

function runCommandSlaveStreamServers(){
    counter=2
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ${SSH_USER}@stream-node-0${counter} $1
        else
            nohup ssh ${SSH_USER}@stream-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandKafkaServers(){
    counter=1
    while [ ${counter} -le ${KAFKA_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ${SSH_USER}@kafka-node-0${counter} $1
        else
            nohup ssh ${SSH_USER}@kafka-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandZKServers(){
    counter=1
    while [ ${counter} -le ${ZOOKEEPER_SERVER_COUNT} ]
    do
       if [ "$2" != "nohup" ]; then
           ssh ${SSH_USER}@zookeeper-node-0${counter} $1
       else
           nohup ssh ${SSH_USER}@zookeeper-node-0${counter} $1 &
       fi
       ((counter++))
    done
}

function runCommandLoadServers(){
    counter=1
    while [ ${counter} -le ${LOAD_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ${SSH_USER}@load-node-0${counter} $1
        else
            nohup ssh ${SSH_USER}@load-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandRedisServer(){
    if [ "$2" != "nohup" ]; then
        ssh ${SSH_USER}@redisdo $1
    else
        nohup ssh ${SSH_USER}@redisdo $1 &
    fi
}


function getResultFromStreamServer(){
    counter=1
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        nohup scp ${SSH_USER}@stream-node-0${counter}:~/cpu.load $1/stream-node-0${counter}.cpu &
        nohup scp ${SSH_USER}@stream-node-0${counter}:~/mem.load $1/stream-node-0${counter}.mem &
        ((counter++))
    done
}

function getResultFromKafkaServer(){
    counter=1
    while [ ${counter} -le ${KAFKA_SERVER_COUNT} ]
    do
        nohup scp ${SSH_USER}@kafka-node-0${counter}:~/cpu.load $1/kafka-node-0${counter}.cpu &
        nohup scp ${SSH_USER}@kafka-node-0${counter}:~/mem.load $1/kafka-node-0${counter}.mem &
        ((counter++))
    done
}



function getResultFromRedisServer(){
    scp ${SSH_USER}@redisdo:~/stream-benchmarking/data/seen.txt $1/redis-seen.txt
    scp ${SSH_USER}@redisdo:~/stream-benchmarking/data/updated.txt $1/redis-updated.txt
}

function runForRedisDroplets {
    echo "DROPLET: Redis COMMAND: ${1}"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622384/actions"
}

function runForZKDroplets {
    echo "DROPLET: ZooKeeper COMMAND: ${1}"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622254/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622305/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622347/actions"
}

function runForKafkaDroplets {
    echo "DROPLET: Kafka COMMAND: ${1}"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622217/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622172/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622151/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622108/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622068/actions"
}



function runForLoadDroplets {
    echo "DROPLET: Load COMMAND: ${1}"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets//actions"
}

function runForStreamDroplets {
    echo "DROPLET: Stream COMMAND: ${1}"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108619673/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108620670/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621738/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621816/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621767/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621852/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621922/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108621953/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108622493/actions"
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/108626896/actions"
}

function runOnAllDroplets(){
    runForRedisDroplets "${1}"
    runForKafkaDroplets "${1}"
    #runForLoadDroplets "${1}"
    runForStreamDroplets "${1}"
    runForZKDroplets "${1}"
}
