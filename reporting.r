
library(ggplot2)
library(scales)

source('~/Desktop/EDU/THESIS/stream-benchmarking/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/BenchmarkResult.r')

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport("flink")
generateStreamServerLoadReport("flink")
generateKafkaServerLoadReport("flink")


generateBenchmarkReport("spark_2000")
generateStreamServerLoadReport("spark_2000")
generateKafkaServerLoadReport("spark_2000")


generateBenchmarkReport("spark_10000")
generateStreamServerLoadReport("spark_10000")
generateKafkaServerLoadReport("spark_10000")








