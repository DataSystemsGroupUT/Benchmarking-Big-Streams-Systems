/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */
package kafka.benchmark;

import benchmark.common.Utils;
import benchmark.common.advertising.CampaignProcessorCommon;
import benchmark.common.advertising.RedisAdCampaignCache;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.Transformer;
import org.apache.kafka.streams.processor.AbstractProcessor;
import org.apache.kafka.streams.processor.ProcessorContext;
import org.apache.kafka.streams.processor.TimestampExtractor;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple3;
import scala.Tuple7;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Properties;


public class AdvertisingPipeline {

    private static final Logger logger = LoggerFactory.getLogger(AdvertisingPipeline.class);

    static int timeDivisor;
    static  String redisServerHost;
    public static class EnrichedData{

        public EnrichedData(String ad_id, String event_time) {
            this.ad_id = ad_id;
            this.event_time = event_time;
        }

        public EnrichedData(String ad_id, String campaign_id, String event_time) {
            this.ad_id = ad_id;
            this.campaign_id = campaign_id;
            this.event_time = event_time;
        }

        public String ad_id;
        public String campaign_id;
        public String event_time;
    }

    public static void main(final String[] args) throws Exception {

        Options opts = new Options();
        opts.addOption("conf", true, "Path to the config file.");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(opts, args);
        String configPath = cmd.getOptionValue("conf");
        Map commonConfig = Utils.findAndReadConfigFile("./conf/localConf.yaml", true);

        String zkServerHosts = joinHosts((List<String>) commonConfig.get("zookeeper.servers"),
                Integer.toString((Integer) commonConfig.get("zookeeper.port")));
        redisServerHost = (String) commonConfig.get("redis.host");
        String kafkaTopic = (String) commonConfig.get("kafka.topic");
        String kafkaServerHosts = joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();
        int workers = ((Number) commonConfig.get("storm.workers")).intValue();
        int ackers = ((Number) commonConfig.get("storm.ackers")).intValue();
        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        timeDivisor = ((Number) commonConfig.get("time.divisor")).intValue();
        int parallel = Math.max(1, cores / 7);

        logger.info("******************");
        logger.info(redisServerHost);

        Properties config = new Properties();
        config.put(StreamsConfig.TIMESTAMP_EXTRACTOR_CLASS_CONFIG, TimestampExtractorImpl.class);
        config.put(StreamsConfig.APPLICATION_ID_CONFIG, "kafka-benchmark");
        config.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServerHosts);
        config.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        config.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());

        StreamsBuilder builder = new StreamsBuilder();
        builder.stream(kafkaTopic).mapValues(o -> deserializeBolt(o.toString()))
                .filter((o, tuple7) -> tuple7._5().equals("view"))
                .mapValues(tuple7 -> new EnrichedData(tuple7._3(), tuple7._6()))
                .transform(RedisJoinBolt::new)
                .process(CampaignProcessor::new);

//        wordCounts.toStream().to("WordsWithCountsTopic", Produced.with(Serdes.String(), Serdes.Long()));

        KafkaStreams streams = new KafkaStreams(builder.build(), config);
        streams.start();


    }

    public static class TimestampExtractorImpl implements TimestampExtractor {

        public TimestampExtractorImpl() {
        }

        @Override
        public long extract(ConsumerRecord<Object, Object> consumerRecord, long l) {
            return new Date().getTime();
        }
    }


    public static class RedisJoinBolt implements Transformer<Object, EnrichedData, KeyValue<String, EnrichedData>> {

        RedisAdCampaignCache redisAdCampaignCache;

        @Override
        @SuppressWarnings("unchecked")
        public void init(ProcessorContext context) {
            this.redisAdCampaignCache = new RedisAdCampaignCache(redisServerHost);
            this.redisAdCampaignCache.prepare();
        }

        @Override
        public KeyValue<String, EnrichedData> transform(final Object s, final EnrichedData input) {

            String campaign_id = this.redisAdCampaignCache.execute(input.ad_id);
            if (campaign_id == null) {
                return null;
            }
            input.campaign_id = campaign_id;

            return KeyValue.pair(null, input);
        }

        @Override
        public KeyValue<String, EnrichedData> punctuate(long l) {
            return null;
        }

        @Override
        public void close() {

        }
    }



    public static class CampaignProcessor extends AbstractProcessor<String, EnrichedData> {

        CampaignProcessorCommon campaignProcessorCommon;

        @Override
        @SuppressWarnings("unchecked")
        public void init(ProcessorContext context) {
            this.campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, Long.valueOf(timeDivisor));
            this.campaignProcessorCommon.prepare();
        }


        @Override
        public void process(String s, EnrichedData enrichedData) {
            this.campaignProcessorCommon.execute(enrichedData.campaign_id, enrichedData.event_time);

        }
    }


    public static Tuple7<String, String, String, String, String, String, String> deserializeBolt(String value) {

        JSONObject obj = new JSONObject(value);
        Tuple7<String, String, String, String, String, String, String> tuple =
                new Tuple7<>(
                        obj.getString("user_id"),
                        obj.getString("page_id"),
                        obj.getString("ad_id"),
                        obj.getString("ad_type"),
                        obj.getString("event_type"),
                        obj.getString("event_time"),
                        obj.getString("ip_address"));
        return tuple;
    }


    private static String getTimeDivisor(Map conf) {
        if (!conf.containsKey("time.divisor")) {
            throw new IllegalArgumentException("Not time divisor found!");
        }
        return String.valueOf(conf.get("time.divisor"));
    }

    private static String getKafkaTopic(Map conf) {
        if (!conf.containsKey("kafka.topic")) {
            throw new IllegalArgumentException("No kafka topic found!");
        }
        return (String) conf.get("kafka.topic");
    }

    private static String getRedisHost(Map conf) {
        if (!conf.containsKey("redis.host")) {
            throw new IllegalArgumentException("No redis host found!");
        }
        return (String) conf.get("redis.host");
    }

    private static String joinHosts(List<String> hosts, String port) {
        String joined = null;
        for (String s : hosts) {
            if (joined == null) {
                joined = "";
            } else {
                joined += ",";
            }

            joined += s + ":" + port;
        }
//        logger.info("HOSTS " + joined);
        return joined;
    }

}
