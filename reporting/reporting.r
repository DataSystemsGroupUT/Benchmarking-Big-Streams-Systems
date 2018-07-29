#!/usr/bin/env Rscript
library(ggplot2)
library(scales)
library(dplyr)
theme_set(theme_bw())
options("scipen"=10)
args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])
engines <- c("flink","spark_dataset_3000","spark_dstream_3000", "kafka", "storm_without_ack",  "storm_with_ack")
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkResult.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkPercentile.R')
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport(args[1], tps, duration)
generateStreamServerLoadReport(args[1], tps, duration)
generateKafkaServerLoadReport(args[1], tps, duration)


if(length(args) == 0){
  for (i in 1:length(engines)) { 
    generateBenchmarkReport(engines[i], 1000, 600)
    generateStreamServerLoadReport(engines[i], 1000, 600)
    generateKafkaServerLoadReport(engines[i], 1000, 600)
    generateBenchmarkPercentile(engines[i], 1000, 600)
  }
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 99)
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 95)
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 90)
}
  

