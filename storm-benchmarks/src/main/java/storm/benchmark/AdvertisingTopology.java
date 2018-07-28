/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */
package storm.benchmark;

import benchmark.common.Utils;
import benchmark.common.advertising.CampaignProcessorCommon;
import benchmark.common.advertising.RedisAdCampaignCache;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.storm.Config;
import org.apache.storm.LocalCluster;
import org.apache.storm.StormSubmitter;
import org.apache.storm.kafka.spout.KafkaSpout;
import org.apache.storm.kafka.spout.KafkaSpoutConfig;
import org.apache.storm.task.OutputCollector;
import org.apache.storm.task.TopologyContext;
import org.apache.storm.topology.OutputFieldsDeclarer;
import org.apache.storm.topology.TopologyBuilder;
import org.apache.storm.topology.base.BaseRichBolt;
import org.apache.storm.tuple.Fields;
import org.apache.storm.tuple.Tuple;
import org.apache.storm.tuple.Values;
import org.json.JSONObject;

import java.util.List;
import java.util.Map;

import static java.lang.System.out;

/**
 * This is a basic example of a Storm topology.
 */
public class AdvertisingTopology {

    public static class DeserializeBolt extends BaseRichBolt {
        OutputCollector _collector;

        Boolean ackEnabled;

        DeserializeBolt(Boolean ackEnabled) {
            this.ackEnabled = ackEnabled;
        }

        @Override
        public void prepare(Map conf, TopologyContext context, OutputCollector collector) {
            _collector = collector;
        }

        @Override
        public void execute(Tuple tuple) {
            JSONObject obj = new JSONObject(tuple.getString(4));
            _collector.emit(tuple, new Values(obj.getString("user_id"),
                    obj.getString("page_id"),
                    obj.getString("ad_id"),
                    obj.getString("ad_type"),
                    obj.getString("event_type"),
                    obj.getString("event_time"),
                    obj.getString("ip_address")));
            if (ackEnabled)
                _collector.ack(tuple);
        }

        @Override
        public void declareOutputFields(OutputFieldsDeclarer declarer) {
            declarer.declare(new Fields("user_id", "page_id", "ad_id", "ad_type", "event_type", "event_time", "ip_address"));
        }
    }

    public static class EventFilterBolt extends BaseRichBolt {
        OutputCollector _collector;
        Boolean ackEnabled;

        EventFilterBolt(Boolean ackEnabled) {
            this.ackEnabled = ackEnabled;
        }

        @Override
        public void prepare(Map conf, TopologyContext context, OutputCollector collector) {
            _collector = collector;
        }

        @Override
        public void execute(Tuple tuple) {
            if (tuple.getStringByField("event_type").equals("view")) {
                _collector.emit(tuple, tuple.getValues());
            }
            if (ackEnabled)
                _collector.ack(tuple);
        }

        @Override
        public void declareOutputFields(OutputFieldsDeclarer declarer) {
            declarer.declare(new Fields("user_id", "page_id", "ad_id", "ad_type", "event_type", "event_time", "ip_address"));
        }
    }

    public static class EventProjectionBolt extends BaseRichBolt {
        OutputCollector _collector;
        Boolean ackEnabled;

        EventProjectionBolt(Boolean ackEnabled) {
            this.ackEnabled = ackEnabled;
        }

        @Override
        public void prepare(Map conf, TopologyContext context, OutputCollector collector) {
            _collector = collector;
        }

        @Override
        public void execute(Tuple tuple) {
            _collector.emit(tuple, new Values(tuple.getStringByField("ad_id"),
                    tuple.getStringByField("event_time")));
            if (ackEnabled)
                _collector.ack(tuple);
        }

        @Override
        public void declareOutputFields(OutputFieldsDeclarer declarer) {
            declarer.declare(new Fields("ad_id", "event_time"));
        }
    }

    public static class RedisJoinBolt extends BaseRichBolt {
        private OutputCollector _collector;
        transient RedisAdCampaignCache redisAdCampaignCache;
        private String redisServerHost;

        private Boolean ackEnabled;

        RedisJoinBolt(String redisServerHost, Boolean ackEnabled) {
            this.redisServerHost = redisServerHost;
            this.ackEnabled = ackEnabled;
        }

        public void prepare(Map conf, TopologyContext context, OutputCollector collector) {
            _collector = collector;
            redisAdCampaignCache = new RedisAdCampaignCache(redisServerHost);
            this.redisAdCampaignCache.prepare();
        }

        @Override
        public void execute(Tuple tuple) {
            String ad_id = tuple.getStringByField("ad_id");
            String campaign_id = this.redisAdCampaignCache.execute(ad_id);
            if (campaign_id == null) {
                _collector.fail(tuple);
                return;
            }
            _collector.emit(tuple, new Values(campaign_id,
                    tuple.getStringByField("ad_id"),
                    tuple.getStringByField("event_time")));
            if (ackEnabled)
                _collector.ack(tuple);
        }

        @Override
        public void declareOutputFields(OutputFieldsDeclarer declarer) {
            declarer.declare(new Fields("campaign_id", "ad_id", "event_time"));
        }
    }

    public static class CampaignProcessor extends BaseRichBolt {

        private OutputCollector _collector;
        transient private CampaignProcessorCommon campaignProcessorCommon;
        private String redisServerHost;
        private Long timeDivisor;
        private Boolean ackEnabled;

        CampaignProcessor(String redisServerHost, Long timeDivisor, Boolean ackEnabled) {
            this.redisServerHost = redisServerHost;
            this.timeDivisor = timeDivisor;
            this.ackEnabled = ackEnabled;
        }

        public void prepare(Map conf, TopologyContext context, OutputCollector collector) {
            _collector = collector;
            campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, timeDivisor);
            this.campaignProcessorCommon.prepare();
        }

        @Override
        public void execute(Tuple tuple) {

            String campaign_id = tuple.getStringByField("campaign_id");
            String event_time = tuple.getStringByField("event_time");
            this.campaignProcessorCommon.execute(campaign_id, event_time);
            if (ackEnabled)
                _collector.ack(tuple);
        }

        @Override
        public void declareOutputFields(OutputFieldsDeclarer declarer) {
        }
    }


    public static void main(String[] args) throws Exception {
        TopologyBuilder builder = new TopologyBuilder();

        Options opts = new Options();
        opts.addOption("conf", true, "Path to the config file.");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(opts, args);
        String configPath = cmd.getOptionValue("conf");
        Map commonConfig = Utils.findAndReadConfigFile(configPath, true);
        String redisServerHost = (String) commonConfig.get("redis.host");
        String kafkaTopic = (String) commonConfig.get("kafka.topic");
        String kafkaServerHosts = Utils.joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();
        int workers = ((Number) commonConfig.get("storm.workers")).intValue();
        int ackers = ((Number) commonConfig.get("storm.ackers")).intValue();
        Boolean ackEnabled = commonConfig.get("storm.ack").equals("enabled");
        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        int timeDivisor = ((Number) commonConfig.get("time.divisor")).intValue();
        int parallel = Math.max(1, cores / 7);

        out.println("Configuration loading  "+ackEnabled);
        KafkaSpout kafkaSpout = new KafkaSpout(KafkaSpoutConfig.builder(kafkaServerHosts, kafkaTopic).build());

        builder.setSpout("ads", kafkaSpout, kafkaPartitions);
        builder.setBolt("event_deserializer", new DeserializeBolt(ackEnabled), parallel).shuffleGrouping("ads");
        builder.setBolt("event_filter", new EventFilterBolt(ackEnabled), parallel).shuffleGrouping("event_deserializer");
        builder.setBolt("event_projection", new EventProjectionBolt(ackEnabled), parallel).shuffleGrouping("event_filter");
        builder.setBolt("redis_join", new RedisJoinBolt(redisServerHost, ackEnabled), parallel).shuffleGrouping("event_projection");
        builder.setBolt("campaign_processor", new CampaignProcessor(redisServerHost, Long.valueOf(timeDivisor), ackEnabled), parallel * 2)
                .fieldsGrouping("redis_join", new Fields("campaign_id"));

        Config conf = new Config();
        if (args != null && args.length > 0) {
            conf.setNumWorkers(workers);
            conf.setNumAckers(ackers);
            StormSubmitter.submitTopologyWithProgressBar(args[0], conf, builder.createTopology());
        } else {

            LocalCluster cluster = new LocalCluster();
            cluster.submitTopology("test", conf, builder.createTopology());
            org.apache.storm.utils.Utils.sleep(10000);
            cluster.killTopology("test");
            cluster.shutdown();
        }

        out.println("Configuration done ");
    }
}
