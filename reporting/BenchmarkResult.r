
######################################################################################################################################
##########################                                                                                  ##########################
##########################                             Stream Benchmark Result                              ##########################
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

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

engine="kafka"
tps=1000
duration=600
i=13

generateBenchmarkReport <- function(engine, tps, duration){
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
    for(c in 1:(length(Updated$V1)-1)) {
      if(Seen$V1[c] != Seen$V1[c+1] && Updated$V1[c] != Updated$V1[c+1]){
        SeenFiltered <- c(SeenFiltered, Seen$V1[c])
        UpdatedFiltered <- c(UpdatedFiltered, Updated$V1[c])
      }
    }
    windows <- 1:length(UpdatedFiltered)
    
    df <- data.frame(toString(tps*i*10), SeenFiltered, UpdatedFiltered - 10000, windows)
    result <- rbind(result, df)
    
    if (length(Seen$V1)  != length(Updated$V1)){ 
      stop("Input data set is wrong. Be sure you have selected correct collections")
    }

    names(df) <- c("TPS","Seen","Throughput", "Percentile")
    ggplot(data=df, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
      geom_smooth(method="loess", se=F) + 
      guides(fill=FALSE) +
      xlab("Windows") + ylab("Window Throughput ms ") +
      ggtitle(paste(toupper(engine), "Benchmark", sep = " ")) +
      theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave( paste(engine, "_", toString(tps*i*10), ".pdf", sep=""), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
  }
  names(result) <- c("TPS","Seen","Throughput", "Percentile")
  result = result[result$Throughput > 0,]
  ggplot(data=result, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
    geom_smooth(method="loess", se=F) + 
    guides(fill=FALSE) +
    xlab("Windows") + ylab("Window Throughput ms ") +
    ggtitle(paste(toupper(engine), "Benchmark", sep = " ")) +
    theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
  ggsave(paste(engine,"_", duration, ".pdf", sep=""), width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)
}
