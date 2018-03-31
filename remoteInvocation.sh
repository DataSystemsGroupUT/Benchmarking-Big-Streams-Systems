#!/usr/bin/env bash

function runCommandStreamServers(){
    counter=1
    while [ ${counter} -le 8 ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@stream-node0${counter} $1
        else
            nohup ssh ubuntu@stream-node0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandKafkaServers(){
    counter=1
    while [ ${counter} -le 4 ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@kafka-node0${counter} $1
        else
            nohup ssh ubuntu@kafka-node0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandZKServers(){
    counter=1
    while [ ${counter} -le 3 ]
    do
       if [ "$2" != "nohup" ]; then
            ssh ubuntu@zookeeper-node0${counter} $1
        else
            nohup ssh ubuntu@zookeeper-node0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandLoadServers(){
    counter=1
    while [ ${counter} -le 3 ]
    do
        if [ "$2" != "nohup" ]; then
            ssh ubuntu@load-node0${counter} $1
        else
            nohup ssh ubuntu@load-node0${counter} $1 &
        fi
        ((counter++))
    done
}

function runCommandRedisServer(){
    if [ "$2" != "nohup" ]; then
        ssh ubuntu@redis $1
    else
        nohup ssh ubuntu@redis $1 &
    fi
}


function getResultFromStreamServer(){
    counter=1
    while [ ${counter} -le 8 ]
    do
        scp ubuntu@stream-node0${counter}:~/stream.pid $1/stream-node0${counter}.pid
        scp ubuntu@stream-node0${counter}:~/stream.process $1/stream-node0${counter}.process
        ((counter++))
    done
}

function getResultFromKafkaServer(){
    counter=1
    while [ ${counter} -le 4 ]
    do
        scp ubuntu@kafka-node0${counter}:~/stream.pid $1/kafka-node0${counter}.pid
        scp ubuntu@kafka-node0${counter}:~/stream.process $1/kafka-node0${counter}.process
        ((counter++))
    done
}



function getResultFromRedisServer(){
    scp ubuntu@redis:~/stream-benchmarking/data/seen.txt $1/redis-seen.txt
    scp ubuntu@redis:~/stream-benchmarking/data/updated.txt $1/redis-updated.txt
}
