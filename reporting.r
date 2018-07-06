#!/usr/bin/env Rscript
library(ggplot2)
library(scales)
theme_set(theme_bw())

args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])

source('~/Desktop/EDU/THESIS/stream-benchmarking/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/BenchmarkResult.r')

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport(args[1], tps, duration)
generateStreamServerLoadReport(args[1], tps, duration)
generateKafkaServerLoadReport(args[1], tps, duration)

if(length(args) == 0){
  generateBenchmarkReport("flink", 1000, 1800)
  generateStreamServerLoadReport("flink", 1000, 1800)
  generateKafkaServerLoadReport("flink", 1000, 1800)
  
  generateBenchmarkReport("spark_dstream_1000", 1000, 1800)
  generateStreamServerLoadReport("spark_dstream_1000", 1000, 1800)
  generateKafkaServerLoadReport("spark_dstream_1000", 1000, 1800)
  
  generateBenchmarkReport("spark_dataset_1000", 1000, 1800)
  generateStreamServerLoadReport("spark_dataset_1000", 1000, 1800)
  generateKafkaServerLoadReport("spark_dataset_1000", 1000, 1800)
  
  generateBenchmarkReport("storm", 1000, 1800)
  generateStreamServerLoadReport("storm", 1000, 1800)
  generateKafkaServerLoadReport("storm", 1000, 1800)
}
  

