#!/usr/bin/env Rscript
library(ggplot2)
library(scales)

args[0]

source('~/Desktop/EDU/THESIS/stream-benchmarking/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/BenchmarkResult.r')

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport("flink")
generateStreamServerLoadReport("flink")
generateKafkaServerLoadReport("flink")


generateBenchmarkReport("spark_dataset_1000")
generateStreamServerLoadReport("spark_dataset_1000")
generateKafkaServerLoadReport("spark_dataset_1000")


generateBenchmarkReport("spark_dstream_1000")
generateStreamServerLoadReport("spark_dstream_1000")
generateKafkaServerLoadReport("spark_dstream_1000")



generateBenchmarkReport("spark_dataset_3000")
generateStreamServerLoadReport("spark_dataset_3000")
generateKafkaServerLoadReport("spark_dataset_3000")

generateBenchmarkReport("spark_dstream_3000")
generateStreamServerLoadReport("spark_dstream_3000")
generateKafkaServerLoadReport("spark_dstream_3000")






