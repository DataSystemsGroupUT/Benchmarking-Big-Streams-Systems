/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.alibaba.jstorm.kafka;

import com.alibaba.jstorm.utils.JStormUtils;

import java.io.Serializable;
import java.util.Map;
import java.util.Properties;


public class KafkaSpoutConfig implements Serializable {


    private static final long serialVersionUID = 1L;

    public String brokers;
    public int numPartitions;
    public String topic;
    public String zkRoot;
    public String groupId;

    public String zkServers;

    public int fetchMaxBytes = 256 * 1024;
    public int fetchWaitMaxMs = 10000;
    public int socketTimeoutMs = 30 * 1000;
    public int socketReceiveBufferBytes = 64 * 1024;
    public long startOffsetTime = -1;
    public boolean fromBeginning = false;
    public String clientId;
    public boolean resetOffsetIfOutOfRange = false;
    public long offsetUpdateIntervalMs = 2000;
    private Properties properties = null;
    private Map stormConf;
    public int batchSendCount = 1;

    public KafkaSpoutConfig() {
    }

    public KafkaSpoutConfig(Properties properties) {
        this.properties = properties;
    }

    public void configure(Map conf) {
        this.stormConf = conf;
        topic = getConfig("kafka.topic", "ad-events");
        zkRoot = getConfig("storm.zookeeper.root", "/jstorm");


        zkServers = getConfig("kafka.zookeeper.hosts", "127.0.0.1:2181");

        brokers = getConfig("kafka.broker.hosts", "127.0.0.1:9092");

        groupId = getConfig("kafka.group.id", "jstorm");

        numPartitions = JStormUtils.parseInt(getConfig("kafka.broker.partitions"), 1);
        fetchMaxBytes = JStormUtils.parseInt(getConfig("kafka.fetch.max.bytes"), 256 * 1024);
        fetchWaitMaxMs = JStormUtils.parseInt(getConfig("kafka.fetch.wait.max.ms"), 10000);
        socketTimeoutMs = JStormUtils.parseInt(getConfig("kafka.socket.timeout.ms"), 30 * 1000);
        socketReceiveBufferBytes = JStormUtils.parseInt(getConfig("kafka.socket.receive.buffer.bytes"), 64 * 1024);
        fromBeginning = JStormUtils.parseBoolean(getConfig("kafka.fetch.from.beginning"), false);
        startOffsetTime = JStormUtils.parseInt(getConfig("kafka.start.offset.time"), -1);
        offsetUpdateIntervalMs = JStormUtils.parseInt(getConfig("kafka.offset.update.interval.ms"), 2000);
        clientId = getConfig("kafka.client.id", "jstorm");
        batchSendCount = JStormUtils.parseInt(getConfig("kafka.spout.batch.send.count"), 1);
    }


    private String getConfig(String key) {
        return getConfig(key, null);
    }

    private String getConfig(String key, String defaultValue) {
        if (properties != null && properties.containsKey(key)) {
            return properties.getProperty(key);
        } else if (stormConf.containsKey(key)) {
            return String.valueOf(stormConf.get(key));
        } else {
            return defaultValue;
        }
    }


    public String getGroupId() {
        return groupId;
    }


    public String getHosts() {
        return brokers;
    }
    

    public String getTopic() {
        return topic;
    }

    public void setTopic(String topic) {
        this.topic = topic;
    }


}
