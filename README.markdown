

<!--
 Copyright 2015, Yahoo Inc.
 Licensed under the terms of the Apache License 2.0. Please see LICENSE file in the project root for terms.
-->

# Comparative Evaluation for the Performance of Big Stream Processing Systems

### Background
This research benchmark got its main concept from Yahoo!’s benchmarking work from 2015. 
Project has been forked from [Yahoo Streaming Benchmark](https://github.com/yahoo/streaming-benchmarks).
However, we did not want to make a new replicate of the same benchmark, as well as extend it by using some other technologies. Some of the engines, frameworks, and libraries that we worked with are the same as the mentioned benchmark’s, where some of them are more modern tools which even didn’t exist 2-3 years and are included into our tests. Moreover, for the engines that were also tested by Yahoo!, we used their newer versions. We acknowledge that three years is a long time regarding today’s technologies development. There were noticeable improvements and changes in the more recent releases of those engines which we could not skip.

### Comparison Engines with Yahoo’s Benchmark
| Tool Name     | Yahoo's version| Our Version   | Important Changes   |
| ------------- |:--------------:| -----:| -----:|
| Flink      | 1.1.3  | 1.5.0| Dynamic Scaling / Key Groups; Kafka Producer Flushes on Checkpoint; Table API and Streaming SQL Enhancements; Async I/O, etc.|
| Spark | 1.6.2       |   2.3.0|   API Stability; Unifying DataFrame and Dataset; New user-defined Functions; Scalable Partition Handling; Continuous Processing, Structured Streaming and etc. |
| Storm| 0.9.7 |1.2.1|    Simple KafkaSpout Configuration; Support for bolt+spout memory configuration; Miscellaneous bugs fixes and improvements. |
| Redis| 3.0.5 |    4.0.8 |    A new replication engine; Native data types RDB format changes; Many other bug fixes and performance improvements. |
| Kafka Broker| 0.8.2.1	|    0.11.0.2|Support for Kafka Stream; Several bug fixes and performance enhancements. |
| Kafka Stream| not tested      |    1.1.0|-|

### Yahoo Streaming Benchmarks 
Code licensed under the Apache 2.0 license. See LICENSE file for terms.


### Setup
We provide a script stream-bench.sh to setup and run the tests on a single node, and to act as an example of what to do when running the tests on a multi-node system. Also, you need to have leiningen installed on your machines before you start the tests (e.g., on Mac OS, you can install by "brew install leiningen").

It takes a list of operations to perform, and options are passed into the script through environment variables. The most significant of these are

#### Operations
   * SETUP - download dependencies (Storm, Spark, Flink, Redis, and Kafka) cleans out any temp files and compiles everything
   * STORM_TEST - Run the test using Storm on a single node
   * SPARK_TEST - Run the test using Spark on a single node
   * FLINK_TEST - Run the test using Flink on a single node
   * KAFKA_TEST  - Run the test using Kafka Stream on a single node
   * HERON_TEST  - Run the test using Heron on a single node
   * STOP_ALL - If something goes wrong stop all processes that were launched for the test.

#### Environment Variables
   * STORM_VERSION - the version of Storm to compile and run against (default 1.2.1)
   * SPARK_VERSION - the version of Spark to compile and run against (default 2.3.0)
   * FLINK_VERSION - the version of Flink to compile and run against (default 1.5.0)
   * HERON_VERSION - the version of Heron to compile and run against (default 0.17.8)
   * KAFKA_STREAM_VERSION - the version of Kafka Stream  to compile and run against (default 1.1.0)
   * KAFKA_VERSION - the version of Kafka Broker to compile and run against (default 0.11.0.2)  
   * LOAD - the number of messages per second to send to be processed (default 1000)
   * TEST_TIME - the number of seconds to run the test for (default 1800)
   * LEIN - the location of the lein executable (default lein)

### The Local Test
The initial test is a simple advertising use case.
Ad events arrive through kafka in a JSON format.  They are parsed to a more usable format, filtered for the ad view events that this processing cares about, the unneeded fields are removed, and then new fields are added by joining the event with campaign data stored in Redis.  Finally the ad views are aggregated by campaign and by time window and stored back into redis, along with a event_time to indicate when they are updated.


### Results
The current set of results that we care about are comparing the latency that a particular processing system can produce at a given input load.
The result of running a test creates a few files data/seen.txt and data/updated.txt  data/seen.txt contains the counts of events for different campaigns and time windows.  data/updated.txt is the latency in ms from when the last event was emitted to kafka for that particular campaign window and when it was written into Redis.


### References
Sanket Chintapalli, Derek Dagit, Bobby Evans, Reza Farivar, Thomas Graves, Mark Holderbaugh, Zhuo Liu, Kyle Nusbaum, Kishorkumar Patil, Boyang Jerry Peng, Paul Poulosky.
"Benchmarking Streaming Computation Engines: Storm, Flink and Spark Streaming. " 
First Annual Workshop on Emerging Parallel and Distributed Runtime Systems and Middleware. IEEE, 2016.

