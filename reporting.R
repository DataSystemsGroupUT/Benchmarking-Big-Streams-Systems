
library(ggplot2)
library(scales)
source('~/Desktop/EDU/THESIS/stream-benchmarking/StreamServerReport.R')
source('~/Desktop/EDU/THESIS/stream-benchmarking/KafkaServerReport.R')
source('~/Desktop/EDU/THESIS/stream-benchmarking/BenchmarkResult.R')

trim <- function (x) gsub("^\\s+|\\s+$", "", x)


generateStreamServerLoadReport("flink")
generateStreamServerLoadReport("spark_2000")
generateStreamServerLoadReport("spark_10000")


generateKafkaServerLoadReport("flink")
generateKafkaServerLoadReport("spark_2000")
generateKafkaServerLoadReport("spark_10000")



generateBenchmarkReport("flink")
generateBenchmarkReport("spark_2000")
generateBenchmarkReport("spark_10000")







