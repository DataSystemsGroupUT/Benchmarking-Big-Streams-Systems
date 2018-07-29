#!/usr/bin/env Rscript
library(ggplot2)
library(scales)
theme_set(theme_bw())
options("scipen"=10)
args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])

source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkResult.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkPercentile.R')
generateBenchmarkReport("flink", 1000, 600)
generateStreamServerLoadReport("flink", 1000, 600)
generateKafkaServerLoadReport("flink", 1000, 600)
generateBenchmarkPercentile("flink", 1000, 60)
  


trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport(args[1], tps, duration)
generateStreamServerLoadReport(args[1], tps, duration)
generateKafkaServerLoadReport(args[1], tps, duration)


if(length(args) == 0){
  generateBenchmarkReport("kafka", 1000, 600)
  generateStreamServerLoadReport("kafka", 1000, 600)
  generateKafkaServerLoadReport("kafka", 1000, 600)


  generateBenchmarkReport("flink", 1000, 600)
  generateStreamServerLoadReport("flink", 1000, 600)
  generateKafkaServerLoadReport("flink", 1000, 600)
  
  generateBenchmarkReport("spark_dstream_3000", 1000, 600)
  generateStreamServerLoadReport("spark_dstream_3000", 1000, 600)
  generateKafkaServerLoadReport("spark_dstream_3000", 1000, 600)
  
  generateBenchmarkReport("spark_dataset_3000", 1000, 600)
  generateStreamServerLoadReport("spark_dataset_3000", 1000, 600)
  generateKafkaServerLoadReport("spark_dataset_3000", 1000, 600)
  
  generateBenchmarkReport("storm_with_ack", 1000, 600)
  generateStreamServerLoadReport("storm_with_ack", 1000, 600)
  generateKafkaServerLoadReport("storm_with_ack", 1000, 600)

}
  

