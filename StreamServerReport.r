

######################################################################################################################################
##########################                        Benchmark Stream Server Load                              ##########################
######################################################################################################################################



generateStreamServerLoadReport <- function(engine, tps, duration){
  for(i in 1:4) {
    TPS = toString(tps*i)
    memoryUsage= NULL
    cpuUsage= NULL
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
    for(x in 1:8) {
      streamPid = read.table(paste(sourceFolder, "stream-node0", x,".pid",sep=""),header=F,stringsAsFactors=F,sep=',')
      dfPid <- data.frame(paste("Stream 0" , x, sep=""), streamPid$V1)
      names(dfPid) <- c("NODE","PID")
      
      if(engine == "flink"){
        dfPid = dfPid[grep("org.apache.flink.runtime", dfPid$PID),]
      } else if(engine == "spark_dstream_1000" || engine == "spark_dstream_3000" || engine == "spark_dstream_10000"
                || engine == "spark_dataset_1000" || engine == "spark_dataset_3000" || engine == "spark_dataset_10000" ) {
        if(x == 1){
          dfPid = dfPid[grep("KafkaRedisAdvertisingStream", dfPid$PID),]
        }else{
          dfPid = dfPid[grep("CoarseGrainedExecutorBackend", dfPid$PID),]
        }
      }
        
      streamNode = read.table(paste(sourceFolder, "stream-node0", x,".process",sep=""),header=F,stringsAsFactors=F,sep=',')
      
      streamFiltredNode <- data.frame(paste("Stream 0" , x, sep=""), streamNode$V1)
      names(streamFiltredNode) <- c("NODE","PID")
      streamFiltredNode = streamFiltredNode[grep(trim(substr(dfPid$PID, 9, 15)), streamFiltredNode$PID),]
      Seconds = c()
      for(i in 1:length(streamFiltredNode$PID)) {
        Seconds[i] = i
      }
      dfCpu <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(streamFiltredNode$PID, 48, 52))), Seconds)
      dfMemory <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(streamFiltredNode$PID, 53, 57))), Seconds)
      cpuUsage <- rbind(cpuUsage, dfCpu)
      memoryUsage <- rbind(memoryUsage, dfMemory)
    }
    
    names(cpuUsage) <- c("NODE","USAGE", "TIME")
    ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_line() +
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("CPU load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Stream Servers CPU load for TPS", TPS)) +
      theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("STREAM", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
    
    names(memoryUsage) <- c("NODE","USAGE","TIME")
    ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_line() +
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("Memory load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Stream Servers MEMORY load for TPS", TPS)) +
      theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("STREAM", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
  }
}

