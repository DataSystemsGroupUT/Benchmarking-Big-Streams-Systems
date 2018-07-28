#!/usr/bin/env bash

STREAM_SERVER_COUNT=10
LOAD_SERVER_COUNT=10
ZOOKEEPER_SERVER_COUNT=3
KAFKA_SERVER_COUNT=5
SSH_USER="root"

CONTENT_TYPE="Content-Type: application/json"
AUTH="Authorization: Bearer 3de6eded7b58005391801a734bc82a8a0dbe12d144cf890cd4983f4908d5c9de"



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
    curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/99907513/actions"
}

function runForZKDroplets {
    echo "DROPLET: ZooKeeper COMMAND: ${1}"
    counter=1
    while [ ${counter} -le ${ZOOKEEPER_SERVER_COUNT} ]
    do
        id=$[counter+99933376]
        curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/${id}/actions"
        ((counter++))
    done
}

function runForKafkaDroplets {
    echo "DROPLET: Kafka COMMAND: ${1}"
    counter=1
    while [ ${counter} -le ${KAFKA_SERVER_COUNT} ]
    do
        id=$[counter+99933236]
        curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/${id}/actions"
        ((counter++))
    done
}



function runForLoadDroplets {
    echo "DROPLET: Load COMMAND: ${1}"
    counter=1
    while [ ${counter} -le ${LOAD_SERVER_COUNT} ]
    do
        id=$[counter+100576060]
        curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}" "https://api.digitalocean.com/v2/droplets/${id}/actions"
        ((counter++))
    done
}

function runForStreamDroplets {
    echo "DROPLET: Stream COMMAND: ${1}"
    counter=1
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        id=$[counter+99932859]
        curl -X POST -H "${CONTENT_TYPE}" -H "${AUTH}" -d "${1}"  "https://api.digitalocean.com/v2/droplets/${id}/actions"
        ((counter++))
    done
}

function runOnAllDroplets(){
    runForRedisDroplets "${1}"
    runForKafkaDroplets "${1}"
    runForLoadDroplets "${1}"
    runForStreamDroplets "${1}"
    runForZKDroplets "${1}"
}
