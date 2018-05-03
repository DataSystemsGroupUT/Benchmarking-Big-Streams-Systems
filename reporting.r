#!/usr/bin/env Rscript
library(ggplot2)
library(scales)

args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])

args


source('~/Desktop/EDU/THESIS/stream-benchmarking/StreamServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/KafkaServerReport.r')
source('~/Desktop/EDU/THESIS/stream-benchmarking/BenchmarkResult.r')

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

generateBenchmarkReport(args[1], tps, duration)
generateStreamServerLoadReport(args[1], tps, duration)
generateKafkaServerLoadReport(args[1], tps, duration)







