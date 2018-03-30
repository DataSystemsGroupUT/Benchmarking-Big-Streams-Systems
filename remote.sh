#!/usr/bin/env bash

TEST_TIME=180
TPS="100"
BATCH="10000"
SHORT_SLEEP=10
LONG_SLEEP=20
WAIT_AFTER_STOP_PRODUCER=240

CLEAN_LOAD_RESULT_CMD="rm stream*;"
CLEAN_RESULT_CMD="cd stream-benchmarking; rm data/*.txt;"

CHANGE_TPS_CMD="sed -i “s/LOAD:-1000/LOAD:-$TPS/g” stream-benchmarking/stream-bench.sh;"

LOAD_START_CMD="cd stream-benchmarking; ./stream-bench.sh START_LOAD;"
LOAD_STOP_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_LOAD;"

DELETE_TOPIC="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-topics.sh --delete --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic ad-events;"
CREATE_TOPIC="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic ad-events;"

START_MONITOR_PROCESS_CMD="top -b -d 1 | grep --line-buffered java > stream.process;"
STOP_MONITOR_PROCESS_CMD="ps aux | grep top | awk {'print \$2'} | xargs sudo kill;"
MONITOR_PID_CMD="ps aux | grep java > stream.pid"

START_FLINK_CMD="cd stream-benchmarking; ./flink-1.4.0/bin/start-cluster.sh;"
STOP_FLINK_CMD="cd stream-benchmarking; ./flink-1.4.0/bin/stop-cluster.sh;"
START_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_FLINK_PROCESSING;"
STOP_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_FLINK_PROCESSING;"

START_SPARK_CMD="cd stream-benchmarking/spark-2.2.1-bin-hadoop2.6; ./sbin/start-all.sh;"
STOP_SPARK_CMD="cd stream-benchmarking/spark-2.2.1-bin-hadoop2.6; ./sbin/stop-all.sh;"
START_SPARK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_SPARK_PROCESSING;"
STOP_SPARK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_SPARK_PROCESSING;"

START_ZK_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/zookeeper-server-start.sh -daemon config/zookeeper.properties"
STOP_ZK_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/zookeeper-server-stop.sh;"

START_KAFKA_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-server-start.sh -daemon config/server.properties"
STOP_KAFKA_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-server-stop.sh;"

START_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh START_REDIS;"
STOP_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_REDIS;"

PULL_GIT="cd stream-benchmarking; git reset --hard HEAD; git pull origin master;"

function pullRepository {
    nohup ssh ubuntu@stream-node01 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node02 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node03 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node04 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node05 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node06 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node07 ${PULL_GIT} &
    nohup ssh ubuntu@stream-node08 ${PULL_GIT} &
    nohup ssh ubuntu@zookeeper-node01 ${PULL_GIT} &
    nohup ssh ubuntu@zookeeper-node02 ${PULL_GIT} &
    nohup ssh ubuntu@zookeeper-node03 ${PULL_GIT} &
    nohup ssh ubuntu@kafka-node01 ${PULL_GIT} &
    nohup ssh ubuntu@kafka-node02 ${PULL_GIT} &
    nohup ssh ubuntu@kafka-node03 ${PULL_GIT} &
    nohup ssh ubuntu@kafka-node04 ${PULL_GIT} &
    nohup ssh ubuntu@load-node01 ${PULL_GIT} &
    nohup ssh ubuntu@load-node02 ${PULL_GIT} &
    nohup ssh ubuntu@load-node03 ${PULL_GIT} &
    nohup ssh ubuntu@redis ${PULL_GIT} &

    sleep ${SHORT_SLEEP}
}

function stopLoadData {
    echo "Main loader stopping node 01"
    nohup ssh ubuntu@load-node01 ${LOAD_STOP_CMD} &
    echo "Main loader stopping node 02"
    nohup ssh ubuntu@load-node02 ${LOAD_STOP_CMD} &
    echo "Main loader stopping node 03"
    nohup ssh ubuntu@load-node03 ${LOAD_STOP_CMD} &
    sleep ${LONG_SLEEP}
    sleep ${LONG_SLEEP}
}

function stopZkLoadData {
    echo "Zookeeper loader stopping node 01"
    nohup ssh ubuntu@zookeeper-node01 ${LOAD_STOP_CMD} &
    echo "Zookeeper loader stopping node 02"
    nohup ssh ubuntu@zookeeper-node02 ${LOAD_STOP_CMD} &
    echo "Zookeeper loader stopping node 03"
    nohup ssh ubuntu@zookeeper-node03 ${LOAD_STOP_CMD} &
}


function startLoadData {
    sleep ${LONG_SLEEP}
    echo "Main loader starting node 01"
    nohup ssh ubuntu@load-node01 ${LOAD_START_CMD} &
    echo "Main loader starting node 02"
    nohup ssh ubuntu@load-node02 ${LOAD_START_CMD} &
    echo "Main loader starting node 03"
    nohup ssh ubuntu@load-node03 ${LOAD_START_CMD} &

}

function startZkLoadData {
    echo "Zookeeper loader starting node 01"
    nohup ssh ubuntu@zookeeper-node01 ${LOAD_START_CMD} &
    echo "Zookeeper loader starting node 02"
    nohup ssh ubuntu@zookeeper-node02 ${LOAD_START_CMD} &
    echo "Zookeeper loader starting node 03"
    nohup ssh ubuntu@zookeeper-node03 ${LOAD_START_CMD} &
}


function cleanKafka {
    echo "Deleted kafka topic"
    ssh ubuntu@redis ${DELETE_TOPIC}
    echo "Created kafka topic"
    ssh ubuntu@redis ${CREATE_TOPIC}
}

function startZK {
    echo "Starting Zookeeper node 01"
    ssh ubuntu@zookeeper-node01 ${START_ZK_CMD}
    echo "Starting Zookeeper node 02"
    ssh ubuntu@zookeeper-node02 ${START_ZK_CMD}
    echo "Starting Zookeeper node 03"
    ssh ubuntu@zookeeper-node03 ${START_ZK_CMD}
}

function stopZK {
    echo "Stopping Zookeeper node 01"
    ssh ubuntu@zookeeper-node01 ${STOP_ZK_CMD}
    echo "Stopping Zookeeper node 02"
    ssh ubuntu@zookeeper-node02 ${STOP_ZK_CMD}
    echo "Stopping Zookeeper node 03"
    ssh ubuntu@zookeeper-node03 ${STOP_ZK_CMD}
}


function startKafka {
    echo "Starting Kafka node 01"
    ssh ubuntu@kafka-node01 ${START_KAFKA_CMD}
    echo "Starting Kafka node 02"
    ssh ubuntu@kafka-node02 ${START_KAFKA_CMD}
    echo "Starting Kafka node 03"
    ssh ubuntu@kafka-node03 ${START_KAFKA_CMD}
    echo "Starting Kafka node 04"
    ssh ubuntu@kafka-node04 ${START_KAFKA_CMD}
}

function stopKafka {
    echo "Stopping Kafka node 01"
    ssh ubuntu@kafka-node01 ${STOP_KAFKA_CMD}
    echo "Stopping Kafka node 02"
    ssh ubuntu@kafka-node02 ${STOP_KAFKA_CMD}
    echo "Stopping Kafka node 03"
    ssh ubuntu@kafka-node03 ${STOP_KAFKA_CMD}
    echo "Stopping Kafka node 04"
    ssh ubuntu@kafka-node04 ${STOP_KAFKA_CMD}
}

function cleanResult {
    echo "Cleaning previous benchmark result"
    ssh ubuntu@stream-node01 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node02 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node03 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node04 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node05 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node06 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node07 ${CLEAN_LOAD_RESULT_CMD}
    ssh ubuntu@stream-node08 ${CLEAN_LOAD_RESULT_CMD}

    ssh ubuntu@load-node01 ${CLEAN_RESULT_CMD}
    ssh ubuntu@load-node02 ${CLEAN_RESULT_CMD}
    ssh ubuntu@load-node03 ${CLEAN_RESULT_CMD}

    ssh ubuntu@zookeeper-node01 ${CLEAN_RESULT_CMD}
    ssh ubuntu@zookeeper-node02 ${CLEAN_RESULT_CMD}
    ssh ubuntu@zookeeper-node03 ${CLEAN_RESULT_CMD}

}

function startFlink {
    echo "Starting Flink"
    ssh ubuntu@stream-node01 ${START_FLINK_CMD}
    sleep ${SHORT_SLEEP}
}

function stopFlink {
    echo "Stopping Flink"
    ssh ubuntu@stream-node01 ${STOP_FLINK_PROC_CMD}

}

function startFlinkProcessing {
    echo "Starting Flink Processing"
    nohup ssh ubuntu@stream-node01 ${START_FLINK_PROC_CMD} &
    sleep ${LONG_SLEEP}
}

function stopFlinkProcessing {
    echo "Stopping Flink Processing"
    nohup ssh ubuntu@stream-node01 ${STOP_FLINK_CMD} &
    sleep ${SHORT_SLEEP}
}

function startSpark {
    echo "Starting Spark"
    ssh ubuntu@stream-node01 ${START_SPARK_CMD}
    sleep ${SHORT_SLEEP}
}

function getProcessId(){
    ssh ubuntu@stream-node01 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node02 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node03 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node04 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node05 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node06 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node07 ${MONITOR_PID_CMD}
    ssh ubuntu@stream-node08 ${MONITOR_PID_CMD}

    ssh ubuntu@kafka-node01 ${MONITOR_PID_CMD}
    ssh ubuntu@kafka-node02 ${MONITOR_PID_CMD}
    ssh ubuntu@kafka-node03 ${MONITOR_PID_CMD}
    ssh ubuntu@kafka-node04 ${MONITOR_PID_CMD}
}

function startMonitoring(){
    nohup ssh ubuntu@stream-node01 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node02 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node03 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node04 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node05 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node06 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node07 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@stream-node08 ${START_MONITOR_PROCESS_CMD} &

    nohup ssh ubuntu@kafka-node01 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@kafka-node02 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@kafka-node03 ${START_MONITOR_PROCESS_CMD} &
    nohup ssh ubuntu@kafka-node04 ${START_MONITOR_PROCESS_CMD} &
}

function stopMonitoring(){
    ssh ubuntu@stream-node01 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node02 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node03 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node04 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node05 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node06 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node07 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@stream-node08 ${STOP_MONITOR_PROCESS_CMD}

    ssh ubuntu@kafka-node01 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@kafka-node02 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@kafka-node03 ${STOP_MONITOR_PROCESS_CMD}
    ssh ubuntu@kafka-node04 ${STOP_MONITOR_PROCESS_CMD}
}

function stopSpark {
    echo "Stopping Spark"
    ssh ubuntu@stream-node01 ${STOP_SPARK_CMD}
}
function startSparkProcessing {
    echo "Starting Spark processing"
    nohup ssh ubuntu@stream-node01 ${START_SPARK_PROC_CMD} &
    sleep ${SHORT_SLEEP}
}

function stopSparkProcessing {
    echo "Stopping Spark processing"
    nohup ssh ubuntu@stream-node01 ${STOP_SPARK_PROC_CMD} &
    sleep ${SHORT_SLEEP}
}

function changeTps(){
    ssh ubuntu@load-node01 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
    ssh ubuntu@load-node02 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
    ssh ubuntu@load-node03 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"

    ssh ubuntu@zookeeper-node01 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
    ssh ubuntu@zookeeper-node02 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
    ssh ubuntu@zookeeper-node03 "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
}


function startRedis {
    echo "Starting Redis"
    nohup ssh ubuntu@redis ${START_REDIS_CMD} &
    sleep ${SHORT_SLEEP}
}

function stopRedis {
    echo "Stopping Redis"
    ssh ubuntu@redis ${STOP_REDIS_CMD}
    sleep ${SHORT_SLEEP}
}


function prepareEnvironment(){
    cleanResult
    startZK
    sleep ${SHORT_SLEEP}
    startKafka
    sleep ${SHORT_SLEEP}
    cleanKafka
    startRedis
}

function destroyEnvironment(){
    sleep ${SHORT_SLEEP}
    stopRedis
    stopKafka
    sleep ${SHORT_SLEEP}
    stopZK
}


function getBenchmarkResult(){

    if ["$1" == "spark"]; then
        echo $1
        PATH_RESULT=result/${1}_${BATCH}/TPS_${TPS}_DURATION_${TEST_TIME}
    else
        PATH_RESULT=result/${1}/TPS_${TPS}_DURATION_${TEST_TIME}
    fi

    echo ${PATH_RESULT}
    rm -rf ${PATH_RESULT};
    mkdir ${PATH_RESULT}
    scp ubuntu@stream-node01:~/stream.pid ${PATH_RESULT}/stream-node01.pid
    scp ubuntu@stream-node02:~/stream.pid ${PATH_RESULT}/stream-node02.pid
    scp ubuntu@stream-node03:~/stream.pid ${PATH_RESULT}/stream-node03.pid
    scp ubuntu@stream-node04:~/stream.pid ${PATH_RESULT}/stream-node04.pid
    scp ubuntu@stream-node05:~/stream.pid ${PATH_RESULT}/stream-node05.pid
    scp ubuntu@stream-node06:~/stream.pid ${PATH_RESULT}/stream-node06.pid
    scp ubuntu@stream-node07:~/stream.pid ${PATH_RESULT}/stream-node07.pid
    scp ubuntu@stream-node08:~/stream.pid ${PATH_RESULT}/stream-node08.pid

    scp ubuntu@stream-node01:~/stream.process ${PATH_RESULT}/stream-node01.process
    scp ubuntu@stream-node02:~/stream.process ${PATH_RESULT}/stream-node02.process
    scp ubuntu@stream-node03:~/stream.process ${PATH_RESULT}/stream-node03.process
    scp ubuntu@stream-node04:~/stream.process ${PATH_RESULT}/stream-node04.process
    scp ubuntu@stream-node05:~/stream.process ${PATH_RESULT}/stream-node05.process
    scp ubuntu@stream-node06:~/stream.process ${PATH_RESULT}/stream-node06.process
    scp ubuntu@stream-node07:~/stream.process ${PATH_RESULT}/stream-node07.process
    scp ubuntu@stream-node08:~/stream.process ${PATH_RESULT}/stream-node08.process
    scp ubuntu@kafka-node01:~/stream.pid ${PATH_RESULT}/kafka-node01.pid
    scp ubuntu@kafka-node02:~/stream.pid ${PATH_RESULT}/kafka-node02.pid
    scp ubuntu@kafka-node03:~/stream.pid ${PATH_RESULT}/kafka-node03.pid
    scp ubuntu@kafka-node04:~/stream.pid ${PATH_RESULT}/kafka-node04.pid

    scp ubuntu@kafka-node01:~/stream.process ${PATH_RESULT}/kafka-node01.process
    scp ubuntu@kafka-node02:~/stream.process ${PATH_RESULT}/kafka-node02.process
    scp ubuntu@kafka-node03:~/stream.process ${PATH_RESULT}/kafka-node03.process
    scp ubuntu@kafka-node04:~/stream.process ${PATH_RESULT}/kafka-node04.process


    scp ubuntu@redis:~/stream-benchmarking/data/seen.txt ${PATH_RESULT}/redis-seen.txt
    scp ubuntu@redis:~/stream-benchmarking/data/updated.txt ${PATH_RESULT}/redis-updated.txt

}

function benchmark(){
    startMonitoring
    startLoadData
    startZkLoadData
    sleep ${TEST_TIME}
    stopZkLoadData
    stopLoadData
    sleep ${WAIT_AFTER_STOP_PRODUCER}
    getProcessId
    stopMonitoring
}


function runSystem(){
    prepareEnvironment
    case $1 in
        flink)
            startFlink
            startFlinkProcessing
            benchmark $1
            stopFlinkProcessing
            stopFlink
        ;;
        spark)
            startSpark
            startSparkProcessing
            benchmark $1
            stopSparkProcessing
            stopSpark
        ;;
    esac
    destroyEnvironment
    getBenchmarkResult $1
}


function benchmarkLoop (){
    while true; do
        pullRepository
        if (("$TPS" > "5000")); then
            break
        fi
        changeTps
        runSystem $1
        TPS=$[$TPS + 1000]
    done
}


case $1 in
    flink)
        benchmarkLoop "flink"
    ;;
    spark)
        benchmarkLoop "spark"
    ;;
    both)
        benchmarkLoop "flink"
        benchmarkLoop "spark"
    ;;
    stop)
        stopZkLoadData
        stopLoadData
        stopMonitoring
        stopSparkProcessing
        stopSpark
        destroyEnvironment
    ;;
    push)
        git add .
        git commit -am "Automatic push message"
        git push origin master
    ;;
    data)
        getBenchmarkResult $1

esac

