
######################################################################################################################################
##########################                                                                                  ##########################
##########################                             Stream Benchmark Result                              ##########################
##########################                                                                                  ##########################
######################################################################################################################################

generateBenchmarkReport <- function(engine){
  result = NULL
  for(i in 1:4) {
    TPS = toString(1000*i)
    reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/", sep = "")
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_1800/", sep = "")
    Seen = read.table(paste(sourceFolder, "redis-seen.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
    Updated = read.table(paste(sourceFolder, "redis-updated.txt",sep=""),header=F,stringsAsFactors=F,sep=',')
    
    SumProceed = c()
    for(i in 1:length(Seen$V1)) {
      SumProceed[i] = sum(Seen$V1[1:i])
    }
    df <- data.frame(TPS, Seen$V1, round(Updated$V1, digits=-2), round(SumProceed*100/sum(Seen$V1),digits=0))
    result <- rbind(result, df)
    
    if (length(Seen$V1)  != length(Updated$V1)){ 
      stop("Input data set is wrong. Be sure you have selected correct collections")
    }
    
    names(df) <- c("TPS","Seen","Throughput", "Percentile")
    ggplot(data=df, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
      geom_line() +
      guides(fill=FALSE) +
      xlab("Percentage of Completed Tuple") + ylab("Window Throughput ms ") +
      ggtitle(paste(toupper(engine), "Benchmark", sep = " ")) +
      theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave( "BENCHMARK_RESULT.pdf", width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
  }
  names(result) <- c("TPS","Seen","Throughput", "Percentile")
  ggplot(data=result, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
    geom_line() +
    guides(fill=FALSE) +
    xlab("Percentage of Completed Tuple") + ylab("Window Throughput ms ") +
    ggtitle(paste(toupper(engine), "Benchmark", sep = " ")) +
    theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
  ggsave("BENCHMARK_RESULT.pdf", width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)

}