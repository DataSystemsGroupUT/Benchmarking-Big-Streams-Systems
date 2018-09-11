#!/usr/bin/env Rscript
library(ggplot2)
library(scales)
library(dplyr)
theme_set(theme_bw())
options("scipen"=10)
args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])
tps_count <- as.numeric(args[4])
engines_all <- c("flink","spark_dataset","spark_dstream", "kafka", "jet", "storm")
engines <- c("flink","spark_dataset","spark_dstream", "kafka", "jet")
storms <- c("storm","storm_no_ack")
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkResult.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/BenchmarkPercentile.R')
source('~/Desktop/EDU/THESIS/stream-benchmarking/reporting/ResourceConsumptionReport.r')
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport(args[1], tps, duration, tps_count)
generateStreamServerLoadReport(args[1], tps, duration, tps_count)
generateKafkaServerLoadReport(args[1], tps, duration, tps_count)
generateBenchmarkPercentile(args[1], tps, duration, tps_count)


tps_count = 15
#generateBenchmarkPercentile("kafka", 1000, 600, 15)

if(length(args) == 0){
  for (i in 1:length(engines_all)) { 
    generateBenchmarkReport(engines_all[i], 1000, 600, tps_count)
    generateStreamServerLoadReport(engines_all[i], 1000, 600, tps_count)
    generateKafkaServerLoadReport(engines_all[i], 1000, 600, tps_count)
    generateBenchmarkPercentile(engines_all[i], 1000, 600, tps_count)
    generateResourceConsumptionReportByTps(engines_all[i], 1000, 600, tps_count)
  }
  generateResourceConsumptionReport(engines, 1000, 600, tps_count)
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 99, tps_count)
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 95, tps_count)
  generateBenchmarkSpesificPercentile(engines, 1000, 600, 90, tps_count)
  
}
  
generateResourceConsumptionReport(engines_all, 1000, 600, 15)


