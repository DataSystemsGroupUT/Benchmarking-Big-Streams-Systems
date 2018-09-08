/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */
package hazelcast.benchmark;

import benchmark.common.Utils;
import benchmark.common.advertising.CampaignProcessorCommon;
import benchmark.common.advertising.RedisAdCampaignCache;
import com.hazelcast.core.ITopic;
import com.hazelcast.jet.Jet;
import com.hazelcast.jet.JetInstance;
import com.hazelcast.jet.config.JobConfig;
import com.hazelcast.jet.core.AbstractProcessor;
import com.hazelcast.jet.kafka.KafkaSources;
import com.hazelcast.jet.pipeline.Pipeline;
import com.hazelcast.jet.pipeline.Sink;
import com.hazelcast.jet.pipeline.Sinks;
import com.hazelcast.jet.server.JetBootstrap;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import redis.clients.jedis.Jedis;
import scala.Tuple2;
import scala.Tuple7;

import java.util.*;
import java.util.function.Consumer;

public class AdvertisingPipeline {

    private static final Logger logger = LoggerFactory.getLogger(AdvertisingPipeline.class);
    private static final String deserializeBolt = "DeserializeBolt";

    public static class AdsFiltered {

        public AdsFiltered(String ad_id, Long event_time) {
            this.ad_id = ad_id;
            this.event_time = event_time;
        }

        public String ad_id;
        public Long event_time;
    }

    public static class AdsEnriched {

        public AdsEnriched() {
        }

        public AdsEnriched(String campaign_id, String ad_id, Long event_time) {
            this.campaign_id = campaign_id;
            this.ad_id = ad_id;
            this.event_time = event_time;
        }

        public String campaign_id;
        public String ad_id;
        public Long event_time;

        public String getCampaign_id() {
            return campaign_id;
        }

        public void setCampaign_id(String campaign_id) {
            this.campaign_id = campaign_id;
        }

        public String getAd_id() {
            return ad_id;
        }

        public void setAd_id(String ad_id) {
            this.ad_id = ad_id;
        }

        public Long getEvent_time() {
            return event_time;
        }

        public void setEvent_time(Long event_time) {
            this.event_time = event_time;
        }
    }

    public static Map<String, String> map;

    public static void main(final String[] args) throws Exception {
        System.setProperty("hazelcast.logging.type", "log4j");

        Options opts = new Options();
        opts.addOption("conf", true, "Path to the config file.");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(opts, args);
        String configPath = cmd.getOptionValue("conf");
//        Map commonConfig = Utils.findAndReadConfigFile("./conf/localConf.yaml", true);
        Map commonConfig = Utils.findAndReadConfigFile(configPath, true);
        String redisServerHost = (String) commonConfig.get("redis.host");
        String kafkaTopic = (String) commonConfig.get("kafka.topic");
        String kafkaServerHosts = Utils.joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();

        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        long timeDivisor = ((Number) commonConfig.get("time.divisor")).longValue();
        int parallel = Math.max(1, cores / 7);
        JetInstance instance = Jet.newJetInstance();

//        JetInstance instance = JetBootstrap.getInstance();
        Jedis jedis = new Jedis(redisServerHost);

        createCustomSink(instance, jedis);

        Properties properties = new Properties();
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, "101");
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServerHosts);
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");


        map = new HashMap<>();
        Pipeline pipeline = Pipeline.create();
        pipeline
                .drawFrom(KafkaSources.kafka(properties, kafkaTopic))
//                .setLocalParallelism(parallel)
                .map(objectObjectEntry -> deserializeBolt(objectObjectEntry.getValue().toString()))
//                .setLocalParallelism(parallel)
                .filter(tuple -> tuple._5().equals("view"))
//                .setLocalParallelism(parallel)
                .map(tuple1 -> new AdsFiltered(tuple1._3(), tuple1._6()))
//                .setLocalParallelism(parallel)
                .customTransform("test2", () -> new RedisJoinBoltP(redisServerHost))
//                .setLocalParallelism(parallel)
                .customTransform("test3", () -> new WriteRedisBoltP(redisServerHost, timeDivisor))


//                .addTimestamps(AdsEnriched::getEvent_time, TimeUnit.SECONDS.toMillis(0))
//                .window(WindowDefinition.tumbling(TimeUnit.SECONDS.toMillis(10)))
//                .groupingKey(AdsEnriched::getCampaign_id)
//                .aggregate(AggregateOperations.counting(), (winStart, winEnd, key, result) -> Tuple2.apply(Tuple2.apply(key, winStart), result))
                .drainTo(Sinks.logger());

        instance.newJob(pipeline);

    }


    public static class RedisJoinBoltP extends AbstractProcessor {


        transient private RedisAdCampaignCache redisAdCampaignCache;
        private String redisServerHost;

        RedisJoinBoltP(String redisServerHost) {
            this.redisServerHost = redisServerHost;
        }

        @Override
        protected void init(Context context) {
            redisAdCampaignCache = new RedisAdCampaignCache(redisServerHost);
            this.redisAdCampaignCache.prepare();
        }

        @Override
        protected boolean tryProcess0(Object item) {
            AdsFiltered adsFiltered = (AdsFiltered) item;
            String campaign_id = this.redisAdCampaignCache.execute(adsFiltered.ad_id);
            if (campaign_id == null)
                return false;
            return this.tryEmit(new AdsEnriched(campaign_id, adsFiltered.ad_id, adsFiltered.event_time));
        }
    }

    public static class WriteRedisBoltP extends AbstractProcessor {


        transient private CampaignProcessorCommon campaignProcessorCommon;
        private String redisServerHost;
        private Long timeDivisor;

        WriteRedisBoltP(String redisServerHost, Long timeDivisor) {
            this.redisServerHost = redisServerHost;
            this.timeDivisor = timeDivisor;
        }

        @Override
        protected void init(Context context) {
            campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, timeDivisor);
            this.campaignProcessorCommon.prepare();
        }

        @Override
        protected boolean tryProcess0(Object item) {
            AdsEnriched adsEnriched = (AdsEnriched) item;
            this.campaignProcessorCommon.execute(adsEnriched.campaign_id, adsEnriched.event_time.toString());
            return true;
        }
    }

    private static void createCustomSink(JetInstance instance, Jedis jedis) {
        ITopic<Tuple2<Tuple2<String, Long>, Long>> topic = instance.getHazelcastInstance().getTopic("topic");
        addListener(topic, e -> {
            logger.info(e.toString());
            writeWindow(jedis, e);
        });
    }

    private static void addListener(ITopic<Tuple2<Tuple2<String, Long>, Long>> topic, Consumer<Tuple2<Tuple2<String, Long>, Long>> consumer) {
        topic.addMessageListener(event -> consumer.accept(event.getMessageObject()));
    }

    private static Sink<Tuple2<Tuple2<String, Long>, Long>> buildTopicSink() {
        return Sinks.<ITopic<Tuple2<Tuple2<String, Long>, Long>>, Tuple2<Tuple2<String, Long>, Long>>
                builder((jet) -> jet.getHazelcastInstance().getTopic("topic")).onReceiveFn(ITopic::publish).build();
    }

//    private static void writeRedisTopLevel(Tuple2<Tuple2<String, Long>, Long> campaign_window_counts, String redisHost) {
//        JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
//        JedisPool jedis = new JedisPool(new JedisPoolConfig(), redisHost, 6379, 2000);
//
//        writeWindow(jedis, campaign_window_counts);
//        jedis.getResource().close();
//    }

    private static void writeWindow(Jedis jedis, Tuple2<Tuple2<String, Long>, Long> campaign_window_counts) {
        Tuple2<String, Long> campaign_window_pair = campaign_window_counts._1;
        String campaign = campaign_window_pair._1;
        String window_timestamp = campaign_window_pair._2.toString();
        Long window_seenCount = campaign_window_counts._2;


        String windowUUID = jedis.hmget(campaign, window_timestamp).get(0);
        if (windowUUID == null) {
            windowUUID = UUID.randomUUID().toString();
            jedis.hset(campaign, window_timestamp, windowUUID);
            String windowListUUID = jedis.hmget(campaign, "windows").get(0);
            if (windowListUUID == null) {
                windowListUUID = UUID.randomUUID().toString();
                jedis.hset(campaign, "windows", windowListUUID);
            }
            jedis.lpush(windowListUUID, window_timestamp);
        }
        jedis.hincrBy(windowUUID, "seen_count", window_seenCount);
        jedis.hset(windowUUID, "time_updated", String.valueOf(System.currentTimeMillis()));

    }

    private static Tuple7<String, String, String, String, String, Long, String> deserializeBolt(String input) {

        JSONObject obj = new JSONObject(input);
        return new Tuple7<>(
                obj.getString("user_id"),
                obj.getString("page_id"),
                obj.getString("ad_id"),
                obj.getString("ad_type"),
                obj.getString("event_type"),
                Long.valueOf(obj.getString("event_time")),
                obj.getString("ip_address"));
    }

}
