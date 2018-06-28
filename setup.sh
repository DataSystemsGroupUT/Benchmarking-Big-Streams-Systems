#! /usr/bin/env bash
sudo apt-get upgrade
sudo add-apt-repository ppa:webupd8team/java 
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt-get install maven
sudo update-alternatives --config java


source /etc/environment
echo $JAVA_HOME

sudo apt-get install make
sudo apt-get install gcc
sudo apt-get install tcl
sudo apt-get install build-essential

sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python2.7

wget -O- https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/install.sh | sudo /bin/bash


wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
sudo mkdir -p /usr/local/bin/
sudo mv ./lein* /usr/local/bin/lein
sudo chmod a+x /usr/local/bin/lein
export PATH=$PATH:/usr/local/bin
lein repl

ssh-keygen -t rsa -P ""
sudo apt-get update
sudo apt-get install git
git clone git@bitbucket.org:elkhan_shahverdi/stream-benchmarking.git
cd stream-benchmarking
./stream-bench.sh SETUP
sudo reboot


sed -i 's/taskmanager.heap.mb: 1024/taskmanager.heap.mb: 6144/g' /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/flink-conf.yaml
sed -i 's/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: 4/g' /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/flink-conf.yaml
sed -i 's/jobmanager.rpc.address: localhost/jobmanager.rpc.address: stream-node01/g' /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/flink-conf.yaml
cp /dev/null /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node02" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node03" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node04" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node05" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node06" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node07" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
echo "stream-node08" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/slaves
cp /dev/null /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/masters
echo "stream-node01" >> /home/ubuntu/stream-benchmarking/flink-1.4.0/conf/masters


sed -i 's/zookeeper.connect=zookeeper:2181/zookeeper.connect=zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181/g' /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/server.properties
sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect=zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181/g' /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/server.properties

sed -i 's/maxClientCnxns=0/maxClientCnxns=0/g' /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "tickTime=2000" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "initLimit=20" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "syncLimit=10" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.1=zookeeper-node01:2888:3888" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.2=zookeeper-node02:2888:3888" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties
echo "server.3=zookeeper-node03:2888:3888" >> /home/ubuntu/stream-benchmarking/kafka_2.11-0.11.0.2/config/zookeeper.properties

mkdir /tmp/zookeeper/ -p
touch /tmp/zookeeper/myid

echo '1' >> myid


git remote set-url origin git@bitbucket.org:elkhan_shahverdi/stream-benchmarking.git
git reset --hard HEAD
git pull

#Spark
./sbin/start-master.sh -h stream-node01 -p 7077
./sbin/start-slave.sh spark://stream-node01:7077


#Run zookeeper
./bin/zookeeper-server-start.sh config/zookeeper.properties
./bin/zookeeper-server-start.sh -daemon config/zookeeper.properties;

#Run kafka server
./bin/kafka-server-start.sh config/server.properties
./bin/kafka-server-start.sh -daemon config/server.properties;tail -100f logs/kafkaServer.out
./bin/kafka-server-stop.sh
#List kafka topic
./bin/kafka-topics.sh --list --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181


#Create Kafka topic
./bin/kafka-topics.sh --delete --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic ad-events
./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic ad-events
./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic sample-test

./bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 2 --topic ad-events

#Producer
./bin/kafka-console-producer.sh --broker-list  kafka-node01:9092,kafka-node02:9092,kafka-node03:9092,kafka-node04:9092 --topic sample-test

#Consumer
./bin/kafka-console-consumer.sh --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic sample-test --from-beginning



scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node01:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node02:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node03:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node04:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node05:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node06:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node07:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml
scp apache-storm-1.2.1/conf/storm.yaml ubuntu@stream-node08:~/stream-benchmarking/apache-storm-1.2.1/conf/storm.yaml



