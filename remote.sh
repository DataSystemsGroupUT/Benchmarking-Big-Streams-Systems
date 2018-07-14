#!/usr/bin/env bash


TEST_TIME=600

TPS="1000"
TPS_RANGE=1000
TPS_LIMIT=10000

INITIAL_TPS=${TPS}
BATCH="1000"
SHORT_SLEEP=5
LONG_SLEEP=10

WAIT_AFTER_STOP_PRODUCER=60
WAIT_AFTER_REBOOT_SERVER=30

SSH_USER="root"
KAFKA_PARTITION=150
#KAFKA_FOLDER="kafka_2.11-0.11.0.2"
KAFKA_FOLDER="kafka_2.11-1.1.0"

CLEAN_LOAD_RESULT_CMD="rm *.load;rm -rf /root/stream-benchmarking/apache-storm-1.2.1/logs/*;rm -rf /root/stream-benchmarking/spark-2.3.0-bin-hadoop2.6/work/*;rm -rf /root/kafka-logs/*;"
REBOOT_CMD="reboot;"
CLEAN_RESULT_CMD="cd stream-benchmarking; rm data/*.txt; rm -rf /root/zookeeper/version-2;"

CLEAN_BUILD_BENCHMARK="cd stream-benchmarking; ./stream-bench.sh SETUP_BENCHMARK"
SETUP_KAFKA="cd stream-benchmarking; ./stream-bench.sh SETUP_KAFKA"

CHANGE_TPS_CMD="sed -i “s/LOAD:-1000/LOAD:-$TPS/g” stream-benchmarking/stream-bench.sh;"

LOAD_START_CMD="cd stream-benchmarking; ./stream-bench.sh START_LOAD;"
LOAD_STOP_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_LOAD;"

DELETE_TOPIC="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/kafka-topics.sh --delete --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic ad-events;"
CREATE_TOPIC="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions $KAFKA_PARTITION --topic ad-events;"

START_MONITOR_CPU="top -b -d 1 | grep --line-buffered Cpu > cpu.load;"
START_MONITOR_MEM="top -b -d 1 | grep --line-buffered 'KiB Mem' > mem.load;"
STOP_MONITOR="ps aux | grep top | awk {'print \$2'} | xargs sudo kill;"

START_STORM_NIMBUS_CMD="cd stream-benchmarking; ./apache-storm-1.2.1/bin/storm nimbus;"
STOP_STORM_NIMBUS_CMD="ps aux | grep storm | awk {'print \$2'} | xargs sudo kill;"
START_STORM_SUPERVISOR_CMD="cd stream-benchmarking; ./apache-storm-1.2.1/bin/storm supervisor;"
STOP_STORM_SUPERVISOR_CMD="ps aux | grep storm | awk {'print \$2'} | xargs sudo kill;"
START_STORM_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_STORM_TOPOLOGY;"
STOP_STORM_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_STORM_TOPOLOGY;"

START_FLINK_CMD="cd stream-benchmarking; ./flink-1.5.0/bin/start-cluster.sh;"
STOP_FLINK_CMD="cd stream-benchmarking; ./flink-1.5.0/bin/stop-cluster.sh;"
START_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_FLINK_PROCESSING;"
STOP_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_FLINK_PROCESSING;"

START_SPARK_CMD="cd stream-benchmarking/spark-2.3.0-bin-hadoop2.6; ./sbin/start-all.sh;"
STOP_SPARK_CMD="cd stream-benchmarking/spark-2.3.0-bin-hadoop2.6; ./sbin/stop-all.sh;"
START_SPARK_RDD_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_SPARK_CP_PROCESSING;"
STOP_SPARK_RDD_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_SPARK_CP_PROCESSING;"

START_SPARK_DSTREAM_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_SPARK_PROCESSING;"
STOP_SPARK_DSTREAM_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_SPARK_PROCESSING;"

START_SPARK_DATASET_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_SPARK_CP_PROCESSING;"
STOP_SPARK_DATASET_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_SPARK_CP_PROCESSING;"


START_ZK_CMD="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/zookeeper-server-start.sh -daemon config/zookeeper.properties"
STOP_ZK_CMD="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/zookeeper-server-stop.sh;"

START_KAFKA_CMD="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/kafka-server-start.sh -daemon config/server.properties"
STOP_KAFKA_CMD="cd stream-benchmarking/$KAFKA_FOLDER; ./bin/kafka-server-stop.sh;"

START_KAFKA_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_KAFKA_PROCESSING;"
STOP_KAFKA_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_KAFKA_PROCESSING;"

START_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh START_REDIS;"
STOP_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_REDIS;"

PULL_GIT="cd stream-benchmarking; git reset --hard HEAD; git pull origin master;"




. ./remoteInvocation.sh --source-only

function rebootServer {
    runCommandStreamServers "${REBOOT_CMD}" "nohup"
    runCommandZKServers "${REBOOT_CMD}" "nohup"
    runCommandKafkaServers "${REBOOT_CMD}" "nohup"
    runCommandLoadServers "${REBOOT_CMD}" "nohup"
    runCommandRedisServer "${REBOOT_CMD}" "nohup"
}

function pullRepository {
    runCommandStreamServers "${PULL_GIT}" "nohup"
    runCommandZKServers "${PULL_GIT}" "nohup"
    runCommandKafkaServers "${PULL_GIT}" "nohup"
    runCommandLoadServers "${PULL_GIT}" "nohup"
    runCommandRedisServer "${PULL_GIT}" "nohup"
}

function stopLoadData {
    echo "Main loaders stopping"
    runCommandLoadServers "${LOAD_STOP_CMD}" "nohup"
}


function startLoadData {
    echo "Main loaders starting"
    runCommandLoadServers "${LOAD_START_CMD}" "nohup"

}

function cleanKafka {
    #FIXME delete for Kafka benchmark
    echo "Deleted kafka topic"
    runCommandRedisServer "${DELETE_TOPIC}"
    echo "Created kafka topic"
    runCommandRedisServer "${CREATE_TOPIC}"
}

function startZK {
    echo "Starting Zookeepers"
    runCommandZKServers "${START_ZK_CMD}"
}

function stopZK {
    echo "Stopping Zookeepers"
    runCommandZKServers "${STOP_ZK_CMD}"
}


function startKafka {
    echo "Starting Kafka nodes"
    runCommandKafkaServers "${START_KAFKA_CMD}"
}

function stopKafka {
    echo "Stopping Kafka nodes"
    runCommandKafkaServers "${STOP_KAFKA_CMD}"
}

function cleanResult {
    echo "Cleaning previous benchmark result"
    runCommandStreamServers "${CLEAN_LOAD_RESULT_CMD}" "nohup"
    runCommandKafkaServers "${CLEAN_LOAD_RESULT_CMD}" "nohup"
    runCommandRedisServer ${CLEAN_RESULT_CMD} "nohup"
    runCommandZKServers ${CLEAN_RESULT_CMD} "nohup"
}

function startFlink {
    echo "Starting Flink"
    runCommandMasterStreamServers "${START_FLINK_CMD}"
}

function stopFlink {
    echo "Stopping Flink"
    runCommandMasterStreamServers "${STOP_FLINK_CMD}"
}

function startFlinkProcessing {
    echo "Starting Flink Processing"
    runCommandMasterStreamServers "${START_FLINK_PROC_CMD}" "nohup"
}

function stopFlinkProcessing {
    echo "Stopping Flink Processing"
    runCommandMasterStreamServers "${STOP_FLINK_PROC_CMD}" "nohup"
 }

function startSpark {
    echo "Starting Spark"
    runCommandMasterStreamServers "${START_SPARK_CMD}"
}

function stopSpark {
    echo "Stopping Spark"
    runCommandMasterStreamServers "${STOP_SPARK_CMD}"
}

function startSparkProcessing {
    echo "Starting Spark processing"
    case $1 in
        dstream)
            runCommandMasterStreamServers "${START_SPARK_DSTREAM_PROC_CMD}" "nohup"
        ;;
        dataset)
            runCommandMasterStreamServers "${START_SPARK_DATASET_PROC_CMD}" "nohup"
        ;;
        *)
            echo "Which spark processing would you like to start"
        ;;
    esac
}

function stopSparkProcessing {
    echo "Stopping Spark processing"
     case $1 in
        dstream)
            runCommandMasterStreamServers "${STOP_SPARK_DSTREAM_PROC_CMD}" "nohup"
        ;;
        dataset)
            runCommandMasterStreamServers "${STOP_SPARK_DATASET_PROC_CMD}" "nohup"
        ;;
        *)
            echo "Which spark processing would you like to stop"
        ;;
    esac
}


function startKafkaStream {
    echo "Starting Kafka Stream"
    runCommandStreamServers "${START_KAFKA_CMD}"
}

function stopKafkaStream {
    echo "Stopping Kafka Stream"
    runCommandStreamServers "${STOP_KAFKA_CMD}"
}

function startKafkaProcessing {
    echo "Starting Kafka processing"
    runCommandMasterStreamServers "${START_KAFKA_PROC_CMD}" "nohup"
}

function stopKafkaProcessing {
    echo "Stopping Kafka processing"
    runCommandMasterStreamServers "${STOP_KAFKA_PROC_CMD}" "nohup"
}

function startStorm {
    echo "Starting Storm"
    runCommandMasterStreamServers "${START_STORM_NIMBUS_CMD}" "nohup"
    sleep ${SHORT_SLEEP}
    runCommandSlaveStreamServers "${START_STORM_SUPERVISOR_CMD}" "nohup"
}

function stopStorm {
    echo "Stopping Storm"
    runCommandSlaveStreamServers "${STOP_STORM_SUPERVISOR_CMD}" "nohup"
    sleep ${SHORT_SLEEP}
    runCommandMasterStreamServers "${STOP_STORM_NIMBUS_CMD}" "nohup"
}

function startStormProcessing {
    echo "Starting Storm processing"
    runCommandMasterStreamServers "${START_STORM_PROC_CMD}" "nohup"
}

function stopStormProcessing {
    echo "Stopping Storm processing"
    runCommandMasterStreamServers "${STOP_STORM_PROC_CMD}" "nohup"
}

function startMonitoring(){
    echo "Start Monitoring"
    runCommandStreamServers "${START_MONITOR_CPU}" "nohup"
    runCommandStreamServers "${START_MONITOR_MEM}" "nohup"
    runCommandKafkaServers "${START_MONITOR_CPU}" "nohup"
    runCommandKafkaServers "${START_MONITOR_MEM}" "nohup"
}

function stopMonitoring(){
    echo "Stop Monitoring"
    runCommandStreamServers "${STOP_MONITOR}" "nohup"
    runCommandKafkaServers "${STOP_MONITOR}" "nohup"
}

function changeTps(){
    runCommandLoadServers "sed -i \"s/LOAD:-1000/LOAD:-$1/g\" stream-benchmarking/stream-bench.sh" "nohup"
}


function startRedis {
    echo "Starting Redis"
    runCommandRedisServer "${START_REDIS_CMD}" "nohup"
    sleep ${SHORT_SLEEP}
}

function stopRedis {
    echo "Stopping Redis"
    runCommandRedisServer "${STOP_REDIS_CMD}"
    sleep ${SHORT_SLEEP}
}


function prepareEnvironment(){
    cleanResult
    startZK
    sleep ${LONG_SLEEP}
    startKafka
    sleep ${LONG_SLEEP}
    cleanKafka
    startRedis
    sleep ${LONG_SLEEP}
}

function destroyEnvironment(){
    sleep ${SHORT_SLEEP}
    stopRedis
    stopKafka
    sleep ${SHORT_SLEEP}
    stopZK
}


function getBenchmarkResult(){

    if [ "$1" == "spark" ]; then
        ENGINE_PATH=${1}_${2}_${BATCH}
        SUB_PATH=TPS_${TPS}_DURATION_${TEST_TIME}
        PATH_RESULT=result/${ENGINE_PATH}/${SUB_PATH}
    else
        ENGINE_PATH=${1}
        SUB_PATH=TPS_${TPS}_DURATION_${TEST_TIME}
        PATH_RESULT=result/${ENGINE_PATH}/${SUB_PATH}
    fi
    rm -rf ${PATH_RESULT};
    mkdir -p ${PATH_RESULT}
    getResultFromStreamServer "${PATH_RESULT}"
    getResultFromKafkaServer "${PATH_RESULT}"
    getResultFromRedisServer "${PATH_RESULT}"
    sleep ${SHORT_SLEEP}
    Rscript reporting.R ${ENGINE_PATH} ${INITIAL_TPS} ${TEST_TIME}
}

function benchmark(){
    sleep ${LONG_SLEEP}
    startMonitoring
    startLoadData
    sleep ${TEST_TIME}
    stopLoadData
    sleep ${LONG_SLEEP}
    stopMonitoring
    sleep ${WAIT_AFTER_STOP_PRODUCER}
}


function runSystem(){
    case $1 in
        flink)
            prepareEnvironment
            startFlink
            sleep ${SHORT_SLEEP}
            startFlinkProcessing
            benchmark $1
            stopFlinkProcessing
            sleep ${SHORT_SLEEP}
            stopFlink
        ;;
        spark)
            prepareEnvironment
            startSpark
            sleep ${SHORT_SLEEP}
            startSparkProcessing $2
            benchmark $1
            stopSparkProcessing $2
            sleep ${SHORT_SLEEP}
            stopSpark
        ;;
        storm)
            prepareEnvironment
            startStorm
            sleep ${SHORT_SLEEP}
            startStormProcessing
            sleep ${LONG_SLEEP}
            benchmark $1
            stopStormProcessing
            sleep ${SHORT_SLEEP}
            stopStorm
        ;;
        kafka)
            cleanResult
            startZK
            sleep ${LONG_SLEEP}
            startKafka
            startKafkaStream
            sleep ${LONG_SLEEP}
            cleanKafka
            startRedis
            sleep ${LONG_SLEEP}
            startKafkaProcessing
            benchmark $1
            stopKafkaProcessing
            sleep ${SHORT_SLEEP}
            stopKafkaStream
        ;;
    esac
    destroyEnvironment
    getBenchmarkResult $1 $2

}

function stopAll (){
    stopLoadData
    stopMonitoring
    stopKafkaProcessing
    stopKafkaStream
    stopFlinkProcessing
    stopFlink
    stopSparkProcessing "dataset"
    stopSparkProcessing "dstream"
    stopSpark
    stopStormProcessing
    stopStorm
    destroyEnvironment
}


function benchmarkLoop (){
    while true; do
        pullRepository
        sleep ${SHORT_SLEEP}
        if (("$TPS" > "$TPS_LIMIT")); then
            break
        fi
        changeTps "${TPS}"
        runSystem $1 $2
        TPS=$[$TPS + $TPS_RANGE]
    done
    rebootServer
    sleep ${WAIT_AFTER_REBOOT_SERVER}
    TPS=${INITIAL_TPS}
}


case $1 in
    flink)
        benchmarkLoop "flink"
    ;;
    spark)
        benchmarkLoop "spark" $2
    ;;
    storm)
        benchmarkLoop "storm"
    ;;
    kafka)
        benchmarkLoop "kafka"
    ;;
    all)
        benchmarkLoop "flink"
        benchmarkLoop "spark" "dataset"
        benchmarkLoop "spark" "dstream"
        benchmarkLoop "storm"

    ;;
    start)
        case $2 in
            flink)
                startFlink
            ;;
            spark)
                startSpark
            ;;
            storm)
                startStorm
            ;;
            process)
                startStormProcessing
            ;;
            zoo)
                startZK
            ;;
            prepare)
                prepareEnvironment
            ;;
        esac
    ;;
    stop)
        case $2 in
            fling)
                stopFlink
            ;;
            spark)
                stopSpark
            ;;
            storm)
                stopStorm
            ;;
            process)
                stopStormProcessing
            ;;
            zoo)
                stopZK
            ;;
            kafka)
                stopKafka
            ;;
            prepare)
                destroyEnvironment
            ;;
            all)
                stopAll
            ;;
        esac
    ;;
    load)
        startLoadData
    ;;
    push)
        git add --all
        git commit -am "$2"
        git push origin master
        pullRepository
    ;;
    report)
        Rscript reporting.R
    ;;
    build)
        runCommandStreamServers "${CLEAN_BUILD_BENCHMARK}" "nohup"
    ;;
    *)
        changeTps 5000
        runSystem "flink"
        #Rscript --vanilla reporting.R "spark_dstream_1000" 1000 60
        #Rscript --vanilla reporting.R "spark_dataset_1000" 1000 60
        #Rscript --vanilla reporting.R "flink" 1000 60
        #Rscript --vanilla reporting.R "storm" 1000 60
        echo "Please Enter valid command"

esac
