#! /usr/bin/env bash

git clone git@bitbucket.org:elkhan_shahverdi/stream-benchmarking.git
cd stream-benchmarking
./stream-bench.sh SETUP

sed -i 's/taskmanager.heap.mb: 1024/taskmanager.heap.mb: 6144/g' /root/stream-benchmarking/flink-1.5.0/conf/flink-conf.yaml
sed -i 's/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: 4/g' /root/stream-benchmarking/flink-1.5.0/conf/flink-conf.yaml
sed -i 's/jobmanager.rpc.address: localhost/jobmanager.rpc.address: stream-node01/g' /root/stream-benchmarking/flink-1.5.0/conf/flink-conf.yaml
cp /dev/null /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node02" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node03" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node04" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node05" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node06" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node07" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node08" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node09" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node10" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
echo "stream-node11" >> /root/stream-benchmarking/flink-1.5.0/conf/slaves
cp /dev/null /root/stream-benchmarking/flink-1.5.0/conf/masters
echo "stream-node01" >> /root/stream-benchmarking/flink-1.5.0/conf/masters


sed -i 's/zookeeper.connect=zookeeper:2181/zookeeper.connect=zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181/g' /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/server.properties

sed -i 's/maxClientCnxns=0/maxClientCnxns=0/g' /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "tickTime=2000" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "initLimit=20" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "syncLimit=10" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.1=zookeeper-node01:2888:3888" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.2=zookeeper-node02:2888:3888" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.3=zookeeper-node03:2888:3888" >> /root/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties

mkdir /tmp/zookeeper/ -p
touch /tmp/zookeeper/myid

echo '1' >> /tmp/zookeeper/myid


##Spark
#./sbin/start-master.sh -h stream-node01 -p 7077
#./sbin/start-slave.sh spark://stream-node01:7077
#
#
##Run zookeeper
#./bin/zookeeper-server-start.sh config/zookeeper.properties
#./bin/zookeeper-server-start.sh -daemon config/zookeeper.properties;
#
##Run kafka server
#./bin/kafka-server-start.sh config/server.properties
#./bin/kafka-server-start.sh -daemon config/server.properties;tail -100f logs/kafkaServer.out
#./bin/kafka-server-stop.sh
##List kafka topic
#./bin/kafka-topics.sh --list --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181
#
#
##Create Kafka topic
#./bin/kafka-topics.sh --delete --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic ad-events
#./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic ad-events
#./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic sample-test
#
#./bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 2 --topic ad-events
#
##Producer
#./bin/kafka-console-producer.sh --broker-list  kafka-node01:9092,kafka-node02:9092,kafka-node03:9092,kafka-node04:9092 --topic sample-test
#
##Consumer
#./bin/kafka-console-consumer.sh --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic sample-test --from-beginning
#
#
#
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node01:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node02:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node03:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node04:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node05:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node06:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node07:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node08:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node09:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node10:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
#scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node11:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml



