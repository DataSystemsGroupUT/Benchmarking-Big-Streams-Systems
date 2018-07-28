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
import com.hazelcast.jet.Job;
import com.hazelcast.jet.Util;
import com.hazelcast.jet.core.AbstractProcessor;
import com.hazelcast.jet.core.DAG;
import com.hazelcast.jet.core.Edge;
import com.hazelcast.jet.core.Vertex;
import com.hazelcast.jet.core.processor.Processors;
import com.hazelcast.jet.function.DistributedFunction;
import com.hazelcast.jet.kafka.KafkaSources;
import com.hazelcast.jet.pipeline.*;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;
import scala.Tuple2;
import scala.Tuple3;
import scala.Tuple7;

import java.util.*;

import static com.hazelcast.jet.core.processor.DiagnosticProcessors.writeLoggerP;

public class AdvertisingPipeline {

    private static final Logger logger = LoggerFactory.getLogger(AdvertisingPipeline.class);
    private static final String deserializeBolt = "DeserializeBolt";

    private static CampaignProcessorCommon campaignProcessorCommon;


    public static class AdsFiltered {

        public AdsFiltered(String ad_id, String event_time) {
            this.ad_id = ad_id;
            this.event_time = event_time;
        }

        public String ad_id;
        public String event_time;
    }

    public static  class AdsEnriched {

        public AdsEnriched(String campaign_id, String ad_id, String event_time) {
            this.campaign_id = campaign_id;
            this.ad_id = ad_id;
            this.event_time = event_time;
        }

        public String campaign_id;
        public String ad_id;
        public String event_time;
    }

    public static  class AdsCalculated {
        public String campaign_id;
        public String ad_id;
        public Long window_time;
    }

    public static    class AdsCounted {
        public String campaign_id;
        public Long window_time;
        public Integer count;
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
        String kafkaServerHosts = joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();

        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        int timeDivisor = ((Number) commonConfig.get("time.divisor")).intValue();
        System.setProperty("hazelcast.logging.type", "log4j");
        logger.info("******************");
        logger.info(redisServerHost);

        JetInstance instance = Jet.newJetInstance();
        campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, 10000L);
        campaignProcessorCommon.prepare();

        Properties properties = new Properties();
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, UUID.randomUUID().toString());
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServerHosts);
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        Pipeline pipeline = Pipeline.create();
        pipeline
                .drawFrom(KafkaSources.kafka(properties, kafkaTopic))
                .map(objectObjectEntry -> deserializeBolt(objectObjectEntry.getValue().toString()))
                .filter(tuple -> tuple._5().equals("view"))
                .map(tuple1 -> new AdsFiltered(tuple1._3(), tuple1._6()))
//                .map(adsFiltered -> queryRedisTopLevel(adsFiltered, redisServerHost));
//                .map(adsEnriched -> campaignProcessorCommon.execute("asd","asd")).setLocalParallelism(1)
//                    campaignProcessorCommon.execute(adsEnriched.campaign_id, adsEnriched.event_time);
//                    return "";
//                }).setLocalParallelism(1)
                .drainTo(Sinks.logger());
//
//                .map(adsEnriched -> new RedisJoinBolt(redisServerHost));
//
//        Job job = instance.newJob(pipeline);

        DAG dag = pipeline.toDag();

// 1. Create vertices
//        Vertex source = dag.newVertex("source", KafkaSources.kafka(properties, kafkaTopic));
//        Vertex transform = dag.newVertex("transform", Processors.map(
//                (String line) -> Util.entry(line, line.length())));
//        Vertex sink = dag.newVertex("sink", Sinks.writeMap("sinkMap"));

// 2. Configure local parallelism
//        source.localParallelism(1);

// 3. Create edges
//        dag.edge(Edge.between(source, transform));
//        dag.edge(Edge.between(transform, sink));


    }

    public static class RedisJoinBolt extends AbstractProcessor  {



        transient private CampaignProcessorCommon campaignProcessorCommon;
        private String redisServerHost;
        private Long timeDivisor;

        RedisJoinBolt(String redisServerHost) {
            setCooperative(false);
            this.redisServerHost = redisServerHost;
        }

        @Override
        protected void init(Context context){
            campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, timeDivisor);
            this.campaignProcessorCommon.prepare();
        }

        @Override
        protected boolean tryProcess1(Object item){
            AdsEnriched adsEnriched = (AdsEnriched) item;
            String campaign_id = adsEnriched.campaign_id;
            String event_time = adsEnriched.event_time;
            this.campaignProcessorCommon.execute(campaign_id, event_time);
            return this.tryEmit(adsEnriched);
        }
    }

    public static class RedisJoinBolt2 implements DistributedFunction<Tuple2, Tuple3> {

        private final RedisAdCampaignCache redisAdCampaignCache;

        public RedisJoinBolt2(String redisHost) {
            this.redisAdCampaignCache = new RedisAdCampaignCache(redisHost);
        }

        @Override
        public Tuple3 apply(Tuple2 tuple) {
            logger.info(tuple.toString());
            String ad_id = tuple._1().toString();
            String campaign_id = redisAdCampaignCache.execute(ad_id);
            if (campaign_id == null) {
                return null;
            }
            return new Tuple3<>(campaign_id, ad_id, tuple._2.toString());
        }
    }

    private static void campaignProcessor(Tuple3 tuple) {
        logger.info(tuple.toString());

        campaignProcessorCommon.execute(tuple._1().toString(), tuple._3().toString());
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


    public static void writeRedisTopLevel(Tuple2<Tuple2<String, Long>, Integer> campaign_window_counts, String redisHost) {
        JedisPool jedis = new JedisPool(new JedisPoolConfig(), redisHost, 6379, 2000);

        writeWindow(jedis, campaign_window_counts);

        jedis.getResource().close();
    }

    public static void writeWindow(JedisPool jedis, Tuple2<Tuple2<String, Long>, Integer> campaign_window_counts) {
        Tuple2<String, Long> campaign_window_pair = campaign_window_counts._1;
        String campaign = campaign_window_pair._1;
        String window_timestamp = campaign_window_pair._2.toString();
        Integer window_seenCount = campaign_window_counts._2;


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


    private static Tuple3<String, String, String> redisJoinBolt(RedisAdCampaignCache redis, Tuple2 tuple) {
        logger.info(tuple.toString());
        String ad_id = tuple._1().toString();
        String campaign_id = redis.execute(ad_id);
        if (campaign_id == null) {
            return null;
        }
        return new Tuple3<>(campaign_id, ad_id, tuple._2.toString());
    }

    public static Tuple7<String, String, String, String, String, String, String> deserializeBolt(String input) {

        JSONObject obj = new JSONObject(input);
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
