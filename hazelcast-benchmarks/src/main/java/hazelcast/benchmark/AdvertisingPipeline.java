/**
 * Copyright 2015, Yahoo Inc.
 * Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
 */
package hazelcast.benchmark;

import benchmark.common.Utils;
import benchmark.common.advertising.CampaignProcessorCommon;
import benchmark.common.advertising.RedisAdCampaignCache;
import com.hazelcast.core.EntryEvent;
import com.hazelcast.jet.Jet;
import com.hazelcast.jet.JetInstance;
import com.hazelcast.jet.core.*;
import com.hazelcast.jet.function.DistributedConsumer;
import com.hazelcast.jet.function.DistributedFunction;
import com.hazelcast.jet.kafka.KafkaProcessors;
import com.hazelcast.jet.kafka.KafkaSources;
import com.hazelcast.jet.pipeline.Pipeline;
import com.hazelcast.jet.pipeline.Sinks;
import com.hazelcast.map.EntryProcessor;
import com.hazelcast.map.listener.EntryAddedListener;
import com.hazelcast.map.listener.EntryUpdatedListener;
import com.sun.istack.internal.NotNull;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Options;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;
import scala.Tuple3;
import scala.Tuple7;

import java.util.*;

import static com.hazelcast.jet.core.processor.DiagnosticProcessors.writeLoggerP;

public class AdvertisingPipeline {

    private static final Logger logger = LoggerFactory.getLogger(AdvertisingPipeline.class);
    private static final String deserializeBolt = "DeserializeBolt";

    private static CampaignProcessorCommon campaignProcessorCommon;
  private static RedisAdCampaignCache redisAdCampaignCache;


    public static void main(final String[] args) throws Exception {

        Options opts = new Options();
        opts.addOption("conf", true, "Path to the config file.");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(opts, args);
        String configPath = cmd.getOptionValue("conf");
        Map commonConfig = Utils.findAndReadConfigFile("./conf/localConf.yaml", true);

        String zkServerHosts = joinHosts((List<String>) commonConfig.get("zookeeper.servers"),
                Integer.toString((Integer) commonConfig.get("zookeeper.port")));
        String redisServerHost = (String) commonConfig.get("redis.host");
        String kafkaTopic = (String) commonConfig.get("kafka.topic");
        String kafkaServerHosts = joinHosts((List<String>) commonConfig.get("kafka.brokers"),
                Integer.toString((Integer) commonConfig.get("kafka.port")));

        int kafkaPartitions = ((Number) commonConfig.get("kafka.partitions")).intValue();
        int workers = ((Number) commonConfig.get("storm.workers")).intValue();
        int ackers = ((Number) commonConfig.get("storm.ackers")).intValue();
        int cores = ((Number) commonConfig.get("process.cores")).intValue();
        int timeDivisor = ((Number) commonConfig.get("time.divisor")).intValue();
        int parallel = Math.max(1, cores / 7);

        logger.info("******************");
        logger.info(redisServerHost);
//        campaignProcessorCommon = new CampaignProcessorCommon(redisServerHost, Long.valueOf(timeDivisor));
//        redisAdCampaignCache= new RedisAdCampaignCache(redisServerHost);
//        campaignProcessorCommon.prepare();
//        redisAdCampaignCache.prepare();



        JetInstance instance = Jet.newJetInstance();



        Properties properties = new Properties();
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, UUID.randomUUID().toString());
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServerHosts);
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

//        Pipeline pipeline = Pipeline.create();
//        pipeline
//                .drawFrom(KafkaSources.kafka(properties, kafkaTopic))
//                .map(objectObjectEntry -> deserializeBolt(objectObjectEntry.getValue().toString()))
//                .filter(tuple -> tuple._5().equals("view"))
//                .map(tuple1 -> new Tuple2<>(tuple1._3(), tuple1._6()));
//                .map(new RedisJoinBolt(redisServerHost).tryProcess(1))
//                .drainTo(Sinks.list("someList"));


        DAG dag = new DAG();



//        Vertex consume = dag.newVertex("consume", KafkaSources.kafka(properties,kafkaTopic));

        Vertex enrich = dag.newVertex("enrich", () -> new RedisJoinBolt(redisServerHost));
        enrich.localParallelism(1);

        Vertex sink = dag.newVertex("sink", writeLoggerP(o -> Arrays.toString((Object[]) o)));


        dag.edge(Edge.between(enrich,sink));



        try {
            instance.newJob(dag).join();
        } finally {
            Jet.shutdownAll();
        }

    }


    public static class RedisJoinBolt extends AbstractProcessor  {

        private static final Logger logger = LoggerFactory.getLogger(RedisJoinBolt.class);

        private final String redisHost;

        private transient RedisAdCampaignCache redisAdCampaignCache;

        RedisJoinBolt(String redisHost) {
            setCooperative(false);
            this.redisHost = redisHost;
        }

        @Override
        protected void init(@NotNull Context context){
            redisAdCampaignCache = new RedisAdCampaignCache(redisHost);
        }

        @Override
        protected boolean tryProcess1(@NotNull Object item){
            Tuple2<String, String> tuple = (Tuple2<String, String>) item;
            String ad_id = tuple._1();
            String campaign_id = redisAdCampaignCache.execute(ad_id);
            if(campaign_id == null){
                return false;
            }
            return this.tryEmit(new Tuple3<>(campaign_id, ad_id, tuple._2));
        }
    }

//    public static class RedisJoinBolt implements DistributedFunction<Tuple2, Tuple3> {
//
//        private final RedisAdCampaignCache redisAdCampaignCache;
//
//        public RedisJoinBolt(String redisHost) {
//            this.redisAdCampaignCache = new RedisAdCampaignCache(redisHost);
//        }
//
//        @Override
//        public Tuple3 apply(Tuple2 tuple) {
//            logger.info(tuple.toString());
//            String ad_id = tuple._1().toString();
//            String campaign_id = redisAdCampaignCache.execute(ad_id);
//            if (campaign_id == null) {
//                return null;
//            }
//            return new Tuple3<>(campaign_id, ad_id, tuple._2.toString());
//        }
//    }

    private static void campaignProcessor(Tuple3 tuple) {
        logger.info(tuple.toString());

        campaignProcessorCommon.execute(tuple._1().toString(), tuple._3().toString());
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
