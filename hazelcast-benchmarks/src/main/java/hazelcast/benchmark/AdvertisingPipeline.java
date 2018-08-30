/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */
package hazelcast.benchmark;

import benchmark.common.Utils;
import benchmark.common.advertising.RedisAdCampaignCache;
import com.hazelcast.core.IMap;
import com.hazelcast.jet.Jet;
import com.hazelcast.jet.JetInstance;
import com.hazelcast.jet.Job;
import com.hazelcast.jet.aggregate.AggregateOperations;
import com.hazelcast.jet.core.AbstractProcessor;
import com.hazelcast.jet.function.DistributedFunction;
import com.hazelcast.jet.kafka.KafkaSources;
import com.hazelcast.jet.pipeline.Pipeline;
import com.hazelcast.jet.pipeline.Sinks;
import com.hazelcast.jet.pipeline.WindowDefinition;
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
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;
import scala.Tuple2;
import scala.Tuple7;

import java.util.*;
import java.util.concurrent.TimeUnit;

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


    public static void main(final String[] args) throws Exception {

        Options opts = new Options();
        opts.addOption("conf", true, "Path to the config file.");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(opts, args);
        String configPath = cmd.getOptionValue("conf");
        Map commonConfig = Utils.findAndReadConfigFile("./conf/localConf.yaml", true);

        String redisServerHost = (String) commonConfig.get("redis.host");
        String kafkaTopic = (String) commonConfig.get("kafka.topic");
        String kafkaServerHosts = Utils.joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();

        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        int timeDivisor = ((Number) commonConfig.get("time.divisor")).intValue();
        System.setProperty("hazelcast.logging.type", "log4j");
        logger.info("******************");
        logger.info(redisServerHost);

        JetInstance instance = Jet.newJetInstance();

        Properties properties = new Properties();
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, UUID.randomUUID().toString());
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServerHosts);
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");

        IMap<String, String> map = instance.getMap("myMap");
        Pipeline pipeline = Pipeline.create();
        pipeline
                .drawFrom(KafkaSources.kafka(properties, kafkaTopic))
                .map(objectObjectEntry -> deserializeBolt(objectObjectEntry.getValue().toString()))
                .filter(tuple -> tuple._5().equals("view"))
                .map(tuple1 -> new AdsFiltered(tuple1._3(), tuple1._6()))
//                .map(new RedisJoinBoltP(redisServerHost)).setLocalParallelism(1)
                .map(adsFiltered -> queryRedisTopLevel(adsFiltered, redisServerHost))
                .addTimestamps(AdsEnriched::getEvent_time, TimeUnit.SECONDS.toMillis(1))
                .window(WindowDefinition.tumbling(TimeUnit.SECONDS.toMillis(10)))
                .groupingKey(AdsEnriched::getCampaign_id)
//                .map(stringLongTimestampedEntry -> stringLongTimestampedEntry.getKey())
//                .groupingKey(ads -> Tuple2.apply(ads.getCampaign_id(), ads.getEvent_time()))
                .aggregate(AggregateOperations.counting(), (winStart, winEnd, key, result) -> Tuple2.apply(Tuple2.apply(key, winStart), result))
//                .aggregate(AggregateOperations.counting(), (winStart, winEnd, key, result) -> String.format("%s %s %5s %4d", winStart, winEnd, key, result))
                .drainTo(Sinks.logger());
//
//                .map(adsEnriched -> new RedisJoinBolt(redisServerHost));
//
        Job job = instance.newJob(pipeline);


    }


    public static class RedisJoinDistrubutedFunction implements DistributedFunction<AdsFiltered, AdsEnriched> {

        private Jedis jedis;
        private IMap<String, String> ad_to_campaign;

        public RedisJoinDistrubutedFunction(String redisHost, IMap<String, String> ad_to_campaign) {
            jedis = new Jedis(redisHost);
            this.ad_to_campaign = ad_to_campaign;
        }

        @Override
        public AdsEnriched apply(AdsFiltered adsFiltered) {
            logger.info(adsFiltered.toString());
            String campaign_id = ad_to_campaign.get(adsFiltered.ad_id);
            if (campaign_id == null) {
                campaign_id = jedis.get(adsFiltered.ad_id);
                if (campaign_id == null) {
                    return null;
                } else {
                    ad_to_campaign.put(adsFiltered.ad_id, campaign_id);
                }
            }
            return new AdsEnriched(campaign_id, adsFiltered.ad_id, adsFiltered.event_time);
        }

        @Override
        public <V> DistributedFunction<V, AdsEnriched> compose(DistributedFunction<? super V, ? extends AdsFiltered> before) {
            return null;
        }
    }

    public static class RedisJoinBoltP extends AbstractProcessor {


        transient private RedisAdCampaignCache redisAdCampaignCache;
        private String redisServerHost;

        RedisJoinBoltP(String redisServerHost) {
            setCooperative(false);
            this.redisServerHost = redisServerHost;
        }

        @Override
        protected void init(Context context) {
            redisAdCampaignCache = new RedisAdCampaignCache(redisServerHost);
            this.redisAdCampaignCache.prepare();
        }

        @Override
        protected boolean tryProcess1(Object item) {
            AdsFiltered adsFiltered = (AdsFiltered) item;
            String campaign_id = this.redisAdCampaignCache.execute(adsFiltered.ad_id);
            return this.tryEmit(new AdsEnriched(campaign_id, adsFiltered.ad_id, adsFiltered.event_time));
        }
    }

    public static AdsEnriched queryRedisTopLevel(AdsFiltered adsFiltered, String redisHost) {
        JedisPool jedis = new JedisPool(new JedisPoolConfig(), redisHost, 6379, 2000);
        Map<String, String> ad_to_campaign = new HashMap<>();
        AdsEnriched adsEnriched = queryRedis(jedis, ad_to_campaign, adsFiltered);
        jedis.getResource().close();
        return adsEnriched;
    }

    public static AdsEnriched queryRedis(JedisPool jedis, Map<String, String> ad_to_campaign, AdsFiltered adsFiltered) {
        String ad_id = adsFiltered.ad_id;
        String campaign_id_cache = ad_to_campaign.get(ad_id);
        if (campaign_id_cache == null) {


            String campaign_id_temp = jedis.getResource().get(ad_id);
            if (campaign_id_temp != null) {
                String campaign_id = campaign_id_temp;
                ad_to_campaign.put(ad_id, campaign_id);
                return new AdsEnriched(campaign_id, adsFiltered.ad_id, adsFiltered.event_time);
                //campaign_id, ad_id, event_time
            } else {
                return new AdsEnriched("Campaign_ID not found in either cache nore Redis for the given ad_id!", adsFiltered.ad_id, adsFiltered.event_time);
            }

        } else {
            return new AdsEnriched(campaign_id_cache, adsFiltered.ad_id, adsFiltered.event_time);
        }

    }

    public static void writeRedisTopLevel(Tuple2<Tuple2<String, Long>, Long> campaign_window_counts, String redisHost) zqw {
        JedisPool jedis = new JedisPool(new JedisPoolConfig(), redisHost, 6379, 2000);

        writeWindow(jedis, campaign_window_counts);

        jedis.getResource().close();
    }

    public static void writeWindow(JedisPool jedis, Tuple2<Tuple2<String, Long>, Long> campaign_window_counts) {
        Tuple2<String, Long> campaign_window_pair = campaign_window_counts._1;
        String campaign = campaign_window_pair._1;
        String window_timestamp = campaign_window_pair._2.toString();
        Long window_seenCount = campaign_window_counts._2;


        String windowUUID = jedis.getResource().hmget(campaign, window_timestamp).get(0);
        if (windowUUID == null) {
            windowUUID = UUID.randomUUID().toString();
            jedis.getResource().hset(campaign, window_timestamp, windowUUID);
            String windowListUUID = jedis.getResource().hmget(campaign, "windows").get(0);
            if (windowListUUID == null) {
                windowListUUID = UUID.randomUUID().toString();
                jedis.getResource().hset(campaign, "windows", windowListUUID);
            }
            jedis.getResource().lpush(windowListUUID, window_timestamp);
        }
        jedis.getResource().hincrBy(windowUUID, "seen_count", window_seenCount);
        jedis.getResource().hset(windowUUID, "time_updated", String.valueOf(System.currentTimeMillis()));

    }

    public static Tuple7<String, String, String, String, String, Long, String> deserializeBolt(String input) {

        JSONObject obj = new JSONObject(input);
        Tuple7<String, String, String, String, String, Long, String> tuple =
                new Tuple7<>(
                        obj.getString("user_id"),
                        obj.getString("page_id"),
                        obj.getString("ad_id"),
                        obj.getString("ad_type"),
                        obj.getString("event_type"),
                        Long.valueOf(obj.getString("event_time")),
                        obj.getString("ip_address"));
        return tuple;
    }

}
