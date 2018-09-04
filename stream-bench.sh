#!/bin/bash
# Copyright 2015, Yahoo Inc.
# Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

LEIN=${LEIN:-lein}
MVN=${MVN:-mvn}
GIT=${GIT:-git}
MAKE=${MAKE:-make}

KAFKA_STREAM_VERSION=${KAFKA_STREAM_VERSION:-"1.1.0"}
KAFKA_VERSION=${KAFKA_VERSION:-"0.11.0.2"}
REDIS_VERSION=${REDIS_VERSION:-"4.0.8"}
SCALA_BIN_VERSION=${SCALA_BIN_VERSION:-"2.11"}
SCALA_SUB_VERSION=${SCALA_SUB_VERSION:-"11"}
STORM_VERSION=${STORM_VERSION:-"1.2.1"}
JSTORM_VERSION=${JSTORM_VERSION:-"1.2.1"}
FLINK_VERSION=${FLINK_VERSION:-"1.6.0"}
SPARK_VERSION=${SPARK_VERSION:-"2.3.0"}
HERON_VERSION=${HERON_VERSION:-"0.17.8"}
HAZELCAST_VERSION=${HAZELCAST_VERSION:-"0.6"}


STORM_DIR="apache-storm-$STORM_VERSION"
REDIS_DIR="redis-$REDIS_VERSION"
KAFKA_DIR="kafka_$SCALA_BIN_VERSION-$KAFKA_VERSION"
KAFKA_STREAM_DIR="kafka_$SCALA_BIN_VERSION-$KAFKA_STREAM_VERSION"
FLINK_DIR="flink-$FLINK_VERSION"
HERON_DIR="heron-$HERON_VERSION"
SPARK_DIR="spark-$SPARK_VERSION-bin-hadoop2.6"
HAZELCAST_DIR="hazelcast-jet-$HAZELCAST_VERSION"


#Get one of the closet apache mirrors
APACHE_MIRROR=$(curl 'https://www.apache.org/dyn/closer.cgi' |   grep -o '<strong>[^<]*</strong>' |   sed 's/<[^>]*>//g' |   head -1)


ZK_HOST="localhost"
ZK_PORT="2181"
ZK_CONNECTIONS="$ZK_HOST:$ZK_PORT"
    TOPIC=${TOPIC:-"ad-events"}
PARTITIONS=${PARTITIONS:-1}
LOAD=${LOAD:-1000}
CONF_FILE=./conf/benchmarkConf.yaml
TEST_TIME=${TEST_TIME:-60}
SPARK_MASTER_HOST="stream-node01"

pid_match() {
   local VAL=`ps -aef | grep "$1" | grep -v grep | awk '{print $2}'`
   echo $VAL
}

start_if_needed() {
  local match="$1"
  shift
  local name="$1"
  shift
  local sleep_time="$1"
  shift
  local PID=`pid_match "$match"`

  if [[ "$PID" -ne "" ]];
  then
    echo "$name is already running..."
  else
    "$@" &
    sleep $sleep_time
  fi
}

stop_if_needed() {
  local match="$1"
  local name="$2"
  local PID=`pid_match "$match"`
  if [[ "$PID" -ne "" ]];
  then
    kill "$PID"
    sleep 1
    local CHECK_AGAIN=`pid_match "$match"`
    if [[ "$CHECK_AGAIN" -ne "" ]];
    then
      kill -9 "$CHECK_AGAIN"
    fi
  else
    echo "No $name instance found to stop"
  fi
}

fetch_untar_file() {
  local FILE="download-cache/$1"
  local URL=$2
  if [[ -e "$FILE" ]];
  then
    echo "Using cached File $FILE"
  else
	mkdir -p download-cache/
    WGET=`which wget`
    CURL=`whereis curl`
    if [ -n "$WGET" ];
    then
      wget -O "$FILE" "$URL"
    elif [ -n "$CURL" ];
    then
      curl -o "$FILE" "$URL"
    else
      echo "Please install curl or wget to continue.";
      exit 1
    fi
  fi

  if [[ ${FILE} = *"heron"* ]];then
    mkdir -p ${HERON_DIR}
    tar -xzvf ${FILE} -C ${HERON_DIR}
  else
    tar -xzvf "$FILE"
  fi

}

create_kafka_topic() {
    local count=`$KAFKA_DIR/bin/kafka-topics.sh --describe --zookeeper "$ZK_CONNECTIONS" --topic ${TOPIC} 2>/dev/null | grep -c ${TOPIC}`
    if [[ "$count" = "0" ]];
    then
        $KAFKA_DIR/bin/kafka-topics.sh --create --zookeeper "$ZK_CONNECTIONS" --replication-factor 1 --partitions ${PARTITIONS} --topic ${TOPIC}
    else
        echo "Kafka topic $TOPIC already exists"
    fi
}

create_kafka_stream_topic() {
    local count=`$KAFKA_STREAM_DIR/bin/kafka-topics.sh --describe --zookeeper "$ZK_CONNECTIONS" --topic ${TOPIC} 2>/dev/null | grep -c ${TOPIC}`
    if [[ "$count" = "0" ]];
    then
        $KAFKA_STREAM_DIR/bin/kafka-topics.sh --create --zookeeper "$ZK_CONNECTIONS" --replication-factor 1 --partitions ${PARTITIONS} --topic ${TOPIC}
    else
        echo "Kafka topic $TOPIC already exists"
    fi
}

run() {
  OPERATION=$1
  if [ "SETUP" = "$OPERATION" ];
  then
    run "SETUP_BENCHMARK"
	run "SETUP_REDIS"
    run "SETUP_KAFKA"
    run "SETUP_KAFKA_STREAM"
    run "SETUP_HERON_UBUNTU"
    run "SETUP_HAZELCAST"
    run "SETUP_STORM"
    run "SETUP_FLINK"
    run "SETUP_SPARK"

  elif [ "SETUP_BENCHMARK" = "$OPERATION" ];
  then
    
    $MVN clean install -Dspark.version="$SPARK_VERSION" -Dkafka.version="$KAFKA_VERSION" -Dkafka.stream.version="$KAFKA_STREAM_VERSION" -Dheron.version="$HERON_VERSION" -Dhazelcast.version="$HAZELCAST_VERSION" -Dflink.version="$FLINK_VERSION" -Dstorm.version="$STORM_VERSION" -Dscala.binary.version="$SCALA_BIN_VERSION" -Dscala.version="$SCALA_BIN_VERSION.$SCALA_SUB_VERSION"
  elif [ "SETUP_REDIS" = "$OPERATION" ];
  then
    
    #Fetch and build Redis
    REDIS_FILE="$REDIS_DIR.tar.gz"
    fetch_untar_file "$REDIS_FILE" "http://download.redis.io/releases/$REDIS_FILE"
    cd $REDIS_DIR
    $MAKE
    cd ..
  elif [ "SETUP_KAFKA" = "$OPERATION" ];
  then
    
    #Fetch Kafka
    KAFKA_FILE="$KAFKA_DIR.tgz"
    fetch_untar_file "$KAFKA_FILE" "$APACHE_MIRROR/kafka/$KAFKA_VERSION/$KAFKA_FILE"
  elif [ "SETUP_KAFKA_STREAM" = "$OPERATION" ];
  then

    #Fetch Kafka
    KAFKA_STREAM_FILE="$KAFKA_STREAM_DIR.tgz"
    fetch_untar_file "$KAFKA_STREAM_FILE" "$APACHE_MIRROR/kafka/$KAFKA_STREAM_VERSION/$KAFKA_STREAM_FILE"
  elif [ "SETUP_FLINK" = "$OPERATION" ];
  then
    
    #Fetch Flink
    FLINK_FILE="$FLINK_DIR-bin-hadoop27-scala_${SCALA_BIN_VERSION}.tgz"
    fetch_untar_file "$FLINK_FILE" "$APACHE_MIRROR/flink/flink-$FLINK_VERSION/$FLINK_FILE"
  elif [ "SETUP_SPARK" = "$OPERATION" ];
  then
    
    #Fetch Spark
    SPARK_FILE="$SPARK_DIR.tgz"
    fetch_untar_file "$SPARK_FILE" "$APACHE_MIRROR/spark/spark-$SPARK_VERSION/$SPARK_FILE"
  elif [ "SETUP_STORM" = "$OPERATION" ];
  then
    
    #Fetch Storm
    STORM_FILE="$STORM_DIR.tar.gz"
    fetch_untar_file "$STORM_FILE" "$APACHE_MIRROR/storm/$STORM_DIR/$STORM_FILE"
  elif [ "SETUP_HAZELCAST" = "$OPERATION" ];
  then
    #Fetch Heron
    HAZELCAST_FILE="$HAZELCAST_DIR.tar.gz"
    fetch_untar_file "$HAZELCAST_FILE" "https://download.hazelcast.com/jet/$HAZELCAST_FILE"
  elif [ "SETUP_HERON_UBUNTU" = "$OPERATION" ];
  then
    
    #Fetch Heron
    HERON_FILE="$HERON_DIR.tgz.gz"
    fetch_untar_file "$HERON_FILE" "https://github.com/twitter/heron/releases/download/$HERON_VERSION/heron-$HERON_VERSION-ubuntu.tar.gz"
  elif [ "SETUP_HERON_DARWIN" = "$OPERATION" ];
  then

    #Fetch Heron
    HERON_FILE="$HERON_DIR.tgz.gz"
    fetch_untar_file "$HERON_FILE" "https://github.com/twitter/heron/releases/download/$HERON_VERSION/heron-$HERON_VERSION-darwin.tar.gz"

  elif [ "START_STORM_ZK" = "$OPERATION" ];
  then
    start_if_needed dev_zookeeper_storm ZooKeeperStorm 10 "$STORM_DIR/bin/storm" dev-zookeeper_storm
  elif [ "STOP_STORM_ZK" = "$OPERATION" ];
  then
    stop_if_needed dev_zookeeper_storm ZooKeeperStorm
    rm -rf /tmp/dev-storm-zookeeper
  elif [ "START_ZK" = "$OPERATION" ];
  then
    start_if_needed zookeeper ZooKeeper 10 $KAFKA_DIR/bin/zookeeper-server-start.sh -daemon $KAFKA_DIR/config/zookeeper.properties
  elif [ "STOP_ZK" = "$OPERATION" ];
  then
    stop_if_needed zookeeper ZooKeeper
    rm -rf /tmp/zookeeper
  elif [ "START_ZK_KAFKA_STREAM" = "$OPERATION" ];
  then
    start_if_needed zookeeper ZooKeeper 10 ${KAFKA_STREAM_DIR}/bin/zookeeper-server-start.sh -daemon ${KAFKA_STREAM_DIR}/config/zookeeper.properties
  elif [ "STOP_ZK_KAFKA_STREAM" = "$OPERATION" ];
  then
    stop_if_needed zookeeper ZooKeeper
    rm -rf /tmp/zookeeper
  elif [ "START_REDIS" = "$OPERATION" ];
  then
    start_if_needed redis-server Redis 1 "$REDIS_DIR/src/redis-server" --protected-mode no
    cd data
    $LEIN run -n --configPath ../$CONF_FILE
    cd ..
  elif [ "LOAD_FROM_REDIS" = "$OPERATION" ];
  then
    cd data
    $LEIN run -g --configPath ../$CONF_FILE || true
    cd ..
  elif [ "STOP_REDIS" = "$OPERATION" ];
  then
    cd data
    $LEIN run -g --configPath ../$CONF_FILE || true
    cd ..
    stop_if_needed redis-server Redis
    rm -f dump.rdb
  elif [ "START_STORM" = "$OPERATION" ];
  then
    start_if_needed daemon.name=nimbus "Storm Nimbus" 3 "$STORM_DIR/bin/storm" nimbus
    start_if_needed daemon.name=supervisor "Storm Supervisor" 3 "$STORM_DIR/bin/storm" supervisor
#    start_if_needed daemon.name=ui "Storm UI" 3 "$STORM_DIR/bin/storm" ui
#    start_if_needed daemon.name=logviewer "Storm LogViewer" 3 "$STORM_DIR/bin/storm" logviewer
    sleep 20
  elif [ "STOP_STORM" = "$OPERATION" ];
  then
    stop_if_needed daemon.name=nimbus "Storm Nimbus"
    stop_if_needed daemon.name=supervisor "Storm Supervisor"
#    stop_if_needed daemon.name=ui "Storm UI"
#    stop_if_needed daemon.name=logviewer "Storm LogViewer"
  elif [ "START_KAFKA" = "$OPERATION" ];
  then
    start_if_needed kafka\.Kafka Kafka 10 "$KAFKA_DIR/bin/kafka-server-start.sh" "$KAFKA_DIR/config/server.properties"
    create_kafka_topic
  elif [ "STOP_KAFKA" = "$OPERATION" ];
  then
    stop_if_needed kafka\.Kafka Kafka
    rm -rf /tmp/kafka-logs/
  elif [ "START_KAFKA_STREAM" = "$OPERATION" ];
  then
    start_if_needed kafka\.Kafka Kafka 10 "$KAFKA_STREAM_DIR/bin/kafka-server-start.sh" "$KAFKA_STREAM_DIR/config/server.properties"
    create_kafka_stream_topic
  elif [ "STOP_KAFKA_STREAM" = "$OPERATION" ];
  then
    stop_if_needed kafka\.Kafka Kafka
    rm -rf /tmp/kafka-logs/
  elif [ "START_FLINK" = "$OPERATION" ];
  then
    start_if_needed org.apache.flink.runtime.jobmanager.JobManager Flink 1 ${FLINK_DIR}/bin/start-cluster.sh
  elif [ "STOP_FLINK" = "$OPERATION" ];
  then
    ${FLINK_DIR}/bin/stop-cluster.sh
  elif [ "START_JET" = "$OPERATION" ];
  then
    start_if_needed HazelcastJet HazelcastJet 1 ${HAZELCAST_DIR}/bin/jet-start.sh
  elif [ "STOP_JET" = "$OPERATION" ];
  then
    ${HAZELCAST_DIR}/bin/jet-stop.sh
  elif [ "START_SPARK" = "$OPERATION" ];
  then
    start_if_needed org.apache.spark.deploy.master.Master SparkMaster 5 $SPARK_DIR/sbin/start-master.sh -h localhost -p 7077
    start_if_needed org.apache.spark.deploy.worker.Worker SparkSlave 5 $SPARK_DIR/sbin/start-slave.sh spark://localhost:7077
  elif [ "STOP_SPARK" = "$OPERATION" ];
  then
    stop_if_needed org.apache.spark.deploy.master.Master SparkMaster
    stop_if_needed org.apache.spark.deploy.worker.Worker SparkSlave
    sleep 3
  elif [ "START_LOAD" = "$OPERATION" ];
  then
    cd data
    start_if_needed leiningen.core.main "Load Generation" 1 $LEIN run -r -t $LOAD --configPath ../$CONF_FILE
    cd ..
  elif [ "STOP_LOAD" = "$OPERATION" ];
  then
    stop_if_needed leiningen.core.main "Load Generation"
  elif [ "START_STORM_TOPOLOGY" = "$OPERATION" ];
  then
    "$STORM_DIR/bin/storm" jar ./storm-benchmarks/target/storm-benchmarks-0.1.0.jar storm.benchmark.AdvertisingTopology test-topo -conf $CONF_FILE
    sleep 15
  elif [ "STOP_STORM_TOPOLOGY" = "$OPERATION" ];
  then
    "$STORM_DIR/bin/storm" kill -w 0 test-topo || true
    sleep 10
  elif [ "START_SPARK_PROCESSING" = "$OPERATION" ];
  then
    "$SPARK_DIR/bin/spark-submit" --master spark://${SPARK_MASTER_HOST}:7077 --class spark.benchmark.KafkaRedisAdvertisingStream ./spark-benchmarks/target/spark-benchmarks-0.1.0.jar "$CONF_FILE" &
    sleep 5
  elif [ "STOP_SPARK_PROCESSING" = "$OPERATION" ];
  then
    stop_if_needed spark.benchmark.KafkaRedisAdvertisingStream "Spark Client Process"
   elif [ "START_SPARK_CP_PROCESSING" = "$OPERATION" ];
  then
    "$SPARK_DIR/bin/spark-submit" --class spark.benchmark.KafkaRedisAdvertisingStream ./spark-cp-benchmarks/target/spark-cp-benchmarks-0.1.0.jar "$CONF_FILE" &
    sleep 5
  elif [ "STOP_SPARK_CP_PROCESSING" = "$OPERATION" ];
  then
    stop_if_needed spark.benchmark.KafkaRedisAdvertisingStream "Spark Client Process"
  elif [ "START_KAFKA_PROCESSING" = "$OPERATION" ];
  then
    java -jar ./kafka-benchmarks/target/kafka-benchmarks-0.1.0.jar -conf $CONF_FILE &
    sleep 3
  elif [ "STOP_KAFKA_PROCESSING" = "$OPERATION" ];
  then
    stop_if_needed kafka-benchmarks kafka-benchmarks
    rm -rf /tmp/kafka-streams/
  elif [ "START_FLINK_PROCESSING" = "$OPERATION" ];
  then
    "$FLINK_DIR/bin/flink" run ./flink-benchmarks/target/flink-benchmarks-0.1.0.jar --confPath $CONF_FILE &
    sleep 3
  elif [ "STOP_FLINK_PROCESSING" = "$OPERATION" ];
  then
    FLINK_ID=`"$FLINK_DIR/bin/flink" list | grep 'Flink Streaming Job' | awk '{print $4}'; true`
    if [ "$FLINK_ID" == "" ];
	then
	  echo "Could not find streaming job to kill"
    else
      "$FLINK_DIR/bin/flink" cancel $FLINK_ID
      sleep 3
    fi
  elif [ "START_JET_PROCESSING" = "$OPERATION" ];
  then
    start_if_needed HazelcastJetProcessing "Hazelcast Jet Processing" 3 "$HAZELCAST_DIR/bin/jet-submit.sh" ./hazelcast-benchmarks/target/hazelcast-benchmarks-0.1.0.jar -conf $CONF_FILE
    sleep 3
  elif [ "START_HERON_PROCESSING" = "$OPERATION" ];
      then
        heron submit local ./heron-benchmarks/target/heron-benchmarks-0.1.0.jar heron.benchmark.AdvertisingHeron test-topo -conf $CONF_FILE  --verbose
        sleep 5
  elif [ "STOP_HERON_PROCESSING" = "$OPERATION" ];
       then
       heron kill local test-topo
  elif [ "START_HERON" = "$OPERATION" ];
       then
        heron-admin standalone cluster start
  elif [ "STOP_HERON" = "$OPERATION" ];
       then
       yes yes | heron-admin standalone cluster stop &
  elif [ "STORM_TEST" = "$OPERATION" ];
  then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_STORM"
    run "START_STORM_TOPOLOGY"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_STORM_TOPOLOGY"
    run "STOP_STORM"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
  elif [ "FLINK_TEST" = "$OPERATION" ];
  then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_FLINK"
    run "START_FLINK_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_FLINK_PROCESSING"
    run "STOP_FLINK"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
  elif [ "JET_TEST" = "$OPERATION" ];
  then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_JET"
    run "START_JET_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_JET"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
  elif [ "SPARK_TEST" = "$OPERATION" ];
  then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_SPARK"
    run "START_SPARK_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_SPARK_PROCESSING"
    run "STOP_SPARK"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
  elif [ "SPARK_CP_TEST" = "$OPERATION" ];
  then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_SPARK"
    run "START_SPARK_CP_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_SPARK_CP_PROCESSING"
    run "STOP_SPARK"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
 elif [ "HERON_TEST" = "$OPERATION" ];
 then
    run "START_ZK"
    run "START_REDIS"
    run "START_KAFKA"
    run "START_HERON"
    run "START_HERON_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_HERON_PROCESSING"
    run "STOP_HERON"
    run "STOP_KAFKA"
    run "STOP_REDIS"
    run "STOP_ZK"
  elif [ "KAFKA_TEST" = "$OPERATION" ];
  then
    run "START_ZK_KAFKA_STREAM"
    run "START_REDIS"
    run "START_KAFKA_STREAM"
    run "START_KAFKA_PROCESSING"
    run "START_LOAD"
    sleep ${TEST_TIME}
    run "STOP_LOAD"
    run "STOP_KAFKA_PROCESSING"
    run "STOP_KAFKA_STREAM"
    run "STOP_REDIS"
    run "STOP_ZK_KAFKA_STREAM"
  elif [ "STOP_ALL" = "$OPERATION" ];
  then
    run "STOP_LOAD"
    run "STOP_SPARK_PROCESSING"
    run "STOP_SPARK"
    run "STOP_JET"
    run "STOP_FLINK_PROCESSING"
    run "STOP_FLINK"
    run "STOP_STORM_TOPOLOGY"
    run "STOP_STORM"
    run "STOP_KAFKA_PROCESSING"
    run "STOP_KAFKA"
    run "STOP_KAFKA_STREAM"
    run "STOP_HERON_PROCESSING"
    run "STOP_HERON"
    run "STOP_REDIS"
    run "STOP_ZK"
    run "STOP_ZK_KAFKA_STREAM"
    run "STOP_ZK_STORM"
  else
    if [ "HELP" != "$OPERATION" ];
    then
      echo "UNKOWN OPERATION '$OPERATION'"
      echo
    fi
    echo "Supported Operations:"
    echo "SETUP: download and setup dependencies for running a single node test"
    echo "START_ZK: run a single node ZooKeeper instance on local host in the background"
    echo "STOP_ZK: kill the ZooKeeper instance"
    echo "START_REDIS: run a redis instance in the background"
    echo "STOP_REDIS: kill the redis instance"
    echo "START_JET: run Hazelcast Jet in the background"
    echo "STOP_JET: kill Hazelcast Jet"
    echo "START_KAFKA: run kafka in the background"
    echo "STOP_KAFKA: kill kafka"
    echo "START_LOAD: run kafka load generation"
    echo "STOP_LOAD: kill kafka load generation"
    echo "START_STORM: run storm daemons in the background"
    echo "STOP_STORM: kill the storm daemons"
    echo "START_FLINK: run flink processes"
    echo "STOP_FLINK: kill flink processes"
    echo "START_SPARK: run spark processes"
    echo "STOP_SPARK: kill spark processes"
    echo "START_HERON: run the Heron test processing"
    echo "STOP_HERON: kill the Heron test processing"
    echo 
    echo "START_STORM_TOPOLOGY: run the storm test topology"
    echo "STOP_STORM_TOPOLOGY: kill the storm test topology"
    echo "START_HERON_PROCESSING: run the heron test topology"
    echo "STOP_HERON_PROCESSING: kill the heron test topology"
    echo "START_FLINK_PROCESSING: run the flink test processing"
    echo "STOP_FLINK_PROCESSING: kill the flink test processing"
    echo "START_KAFKA_PROCESSING: run the kafka test processing"
    echo "STOP_KAFKA_PROCESSING: kill the kafka test processing"
    echo "STOP_JET_PROCESSING: kill the Hazelcast Jet test processing"
    echo "START_JET_PROCESSING: run the Hazelcast Jet test processing"
    echo "START_SPARK_PROCESSING: run the spark test processing"
    echo "STOP_SPARK_PROCESSING: kill the spark test processing"
    echo "START_SPARK_CP_PROCESSING: run the spark structured streaming test processing"
    echo "STOP_SPARK_CP_PROCESSING: kill the spark structured streaming test processing"
    echo
    echo "STORM_TEST: run Storm test (assumes SETUP is done)"
    echo "FLINK_TEST: run Flink test (assumes SETUP is done)"
    echo "SPARK_TEST: run Spark test (assumes SETUP is done)"
    echo "HERON_TEST: run Heron test (assumes SETUP is done)"
    echo "KAFKA_TEST: run Kafka test (assumes SETUP is done)"
    echo "JET_TEST: run Hazelcast test (assumes SETUP is done)"
    echo "STOP_ALL: stop everything"
    echo
    echo "HELP: print out this message"
    echo
    exit 1
  fi
}

if [ $# -lt 1 ];
then
  run "HELP"
else
  while [ $# -gt 0 ];
  do
    run "$1"
    shift
  done
fi
