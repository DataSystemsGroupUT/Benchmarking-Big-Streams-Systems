
######################################################################################################################################
##########################                                                                                  ##########################
##########################                       Stream Benchmark Percentile Result                         ##########################
##########################                                                                                  ##########################
######################################################################################################################################
#!/usr/bin/env Rscript
library(ggplot2)
library(scales)
theme_set(theme_bw())
options("scipen"=10)
args <- commandArgs(TRUE)
tps <- as.numeric(args[2])
duration <- as.numeric(args[3])
percentile <- as.numeric(args[4])
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
#engines <- c("flink", "kafka", "spark_dataset_3000")
#tps=1000
#duration=600
#percentile=99
#eng=1
#i=1

generateBenchmarkSpesificPercentile <- function(engines, tps, duration, percentile){
  result = NULL
  for(eng in 1:length(engines)){
    engine = engines[eng] 
    for(i in 1:15) {
      TPS = toString(tps * i)
      TPS
      reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", sep = "")
      sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
      Seen = read.table(paste(sourceFolder, "redis-seen.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
      Updated = read.table(paste(sourceFolder, "redis-updated.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
      
      windows = c()
      SeenFiltered = c()
      UpdatedFiltered = c()
      for(c in 1:(length(Updated$V1)-1)) {
        if(Seen$V1[c] != Seen$V1[c+1] && Updated$V1[c] != Updated$V1[c+1] && Updated$V1[c] > 10000){
          SeenFiltered <- c(SeenFiltered, Seen$V1[c])
          UpdatedFiltered <- c(UpdatedFiltered, Updated$V1[c])
        }
      }
      UpdatedFiltered <- sort(UpdatedFiltered)
      df <- data.frame(tps*i*10, engine, UpdatedFiltered[round(percentile/100*(length(UpdatedFiltered)+1))]-10000)
      
      result <- rbind(result, df)
      df
      if (length(Seen$V1)  != length(Updated$V1)){ 
        stop("Input data set is wrong. Be sure you have selected correct collections")
      }
      names(df) <- c("TPS","Engine","Throughput")
    }
  }
  names(result) <- c("TPS","Engine","Throughput")
  ggplot(data=result, aes(x=TPS, y=Throughput, group=Engine, colour=Engine)) + 
    geom_point() + geom_smooth(method="loess", se=F) +
    guides(fill=FALSE) +
    scale_x_continuous(breaks = round(seq(min(result$TPS), max(result$TPS), by = 10000),1)) +
    #scale_y_continuous(breaks = round(seq(min(result$Throughput), max(result$Throughput), by = 1000),1)) +
    xlab("Througput (event/s)") + ylab("Window Latency ms ") +
    ggtitle(paste(toupper(engine), toString(percentile), "% Percentile chart", sep = " ")) +
    theme(plot.title = element_text(size = 13, face = "plain"), axis.text.x = element_text(angle = 30, hjust = 1), text = element_text(size = 12, face = "plain"))
  ggsave(paste(duration,"_",percentile,  "_percentile.pdf", sep=""), width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)
}

generateBenchmarkPercentile <- function(engine, tps, duration){
  result = NULL
  for(i in 1:15) {
    TPS = toString(tps * i)
    reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/", sep = "")
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
    Seen = read.table(paste(sourceFolder, "redis-seen.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
    Updated = read.table(paste(sourceFolder, "redis-updated.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
    
    windows = c()
    SeenFiltered = c()
    UpdatedFiltered = c()
    percentile = c()
    for(c in 1:(length(Updated$V1)-1)) {
      if(Seen$V1[c] != Seen$V1[c+1] && Updated$V1[c] != Updated$V1[c+1] && Updated$V1[c] > 10000){
        SeenFiltered <- c(SeenFiltered, Seen$V1[c])
        UpdatedFiltered <- c(UpdatedFiltered, Updated$V1[c])
      }
    }
    UpdatedFiltered <- sort(UpdatedFiltered)
    windows <- 1:100
    for(c in 1:100) {
      percentile[c] = UpdatedFiltered[round(c/100*(length(UpdatedFiltered)+1))]
    }
    
    
    df <- data.frame(toString(tps*i*10), 1:100, percentile - 10000, windows)
    result <- rbind(result, df)
    
    if (length(Seen$V1)  != length(Updated$V1)){ 
      stop("Input data set is wrong. Be sure you have selected correct collections")
    }
    names(df) <- c("TPS","Seen","Throughput", "Percentile")
  }
  names(result) <- c("TPS","Seen","Throughput", "Percentile")
  #result = result[result$Throughput > 0,]
  ggplot(data=result, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
    geom_smooth(method="loess", se=F) + 
    #scale_y_continuous(breaks = round(seq(min(result$Throughput), max(result$Throughput), by = 100),1)) +
    guides(fill=FALSE) +
    xlab("Percentage of Completed Tuple") + ylab("Window Throughput ms ") +
    ggtitle(paste(toupper(engine), "Benchmark Percentile chart", sep = " ")) +
    theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
  ggsave(paste(engine,"_", duration, "_all_percentile.pdf", sep=""), width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)
}
