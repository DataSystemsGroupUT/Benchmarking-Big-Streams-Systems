#!/usr/bin/env bash

STREAM_SERVER_COUNT=10
LOAD_SERVER_COUNT=10
ZOOKEEPER_SERVER_COUNT=3
KAFKA_SERVER_COUNT=5

function runCommandStreamServers(){
    counter=1
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@stream-node-0${counter} $1
        else
            nohup ssh ubuntu@stream-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandMasterStreamServers(){
    if [ "$2" != "nohup" ]; then
        ssh ubuntu@stream-node-01 $1
    else
        nohup ssh ubuntu@stream-node-01 $1 &
    fi
}

function runCommandSlaveStreamServers(){
    counter=2
    while [ ${counter} -le ${STREAM_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@stream-node-0${counter} $1
        else
            nohup ssh ubuntu@stream-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandKafkaServers(){
    counter=1
    while [ ${counter} -le ${KAFKA_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@kafka-node-0${counter} $1
        else
            nohup ssh ubuntu@kafka-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandZKServers(){
    counter=1
    while [ ${counter} -le ${ZOOKEEPER_SERVER_COUNT} ]
    do
       if [ "$2" != "nohup" ]; then
            ssh ubuntu@zookeeper-node-0${counter} $1
        else
            nohup ssh ubuntu@zookeeper-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandLoadServers(){
    counter=1
    while [ ${counter} -le ${LOAD_SERVER_COUNT} ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@load-node-0${counter} $1
        else
            nohup ssh ubuntu@load-node-0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandRedisServer(){
    if [ "$2" != "nohup" ]; then
        ssh ubuntu@redisdo $1
    else
        nohup ssh ubuntu@redisdo $1 &
    fi
}


function getResultFromStreamServer(){
    counter=1
    while [ ${counter} -le 8 ]
    do
        scp ubuntu@stream-node-0${counter}:~/cpu.load $1/stream-node-0${counter}.cpu
        scp ubuntu@stream-node-0${counter}:~/mem.load $1/stream-node-0${counter}.mem
        ((counter++))
    done
}

function getResultFromKafkaServer(){
    counter=1
    while [ ${counter} -le 4 ]
    do
        scp ubuntu@kafka-node-0${counter}:~/cpu.load $1/kafka-node-0${counter}.cpu
        scp ubuntu@kafka-node-0${counter}:~/mem.load $1/kafka-node-0${counter}.mem
        ((counter++))
    done
}



function getResultFromRedisServer(){
    scp ubuntu@redisdo:~/stream-benchmarking/data/seen.txt $1/redis-seen.txt
    scp ubuntu@redisdo:~/stream-benchmarking/data/updated.txt $1/redis-updated.txt
}
