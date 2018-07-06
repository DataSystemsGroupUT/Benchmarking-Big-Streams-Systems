#!/usr/bin/env bash

STREAM_SERVER_COUNT=10
LOAD_SERVER_COUNT=10
ZOOKEEPER_SERVER_COUNT=3
KAFKA_SERVER_COUNT=5
SSH_USER="root"

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
        scp ${SSH_USER}@stream-node-0${counter}:~/cpu.load $1/stream-node-0${counter}.cpu
        scp ${SSH_USER}@stream-node-0${counter}:~/mem.load $1/stream-node-0${counter}.mem
        ((counter++))
    done
}

function getResultFromKafkaServer(){
    counter=1
    while [ ${counter} -le ${KAFKA_SERVER_COUNT} ]
    do
        scp ${SSH_USER}@kafka-node-0${counter}:~/cpu.load $1/kafka-node-0${counter}.cpu
        scp ${SSH_USER}@kafka-node-0${counter}:~/mem.load $1/kafka-node-0${counter}.mem
        ((counter++))
    done
}



function getResultFromRedisServer(){
    scp ${SSH_USER}@redisdo:~/stream-benchmarking/data/seen.txt $1/redis-seen.txt
    scp ${SSH_USER}@redisdo:~/stream-benchmarking/data/updated.txt $1/redis-updated.txt
}
