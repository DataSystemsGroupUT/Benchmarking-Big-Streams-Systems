
######################################################################################################################################
##########################                  Flink Benchmark Kafka Server Load                               ##########################
######################################################################################################################################
generateKafkaServerLoadReport <- function(engine){
  for(i in 1:4) {
    TPS = toString(1000*i)
    memoryUsage= NULL
    cpuUsage= NULL
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_1800/", sep = "")
    for(x in 1:4) {
      kafkaNode = read.table(paste(sourceFolder, "kafka-node0", x,".process",sep=""),header=F,stringsAsFactors=F,sep=',')
      
      Seconds = c()
      for(i in 1:length(kafkaNode$V1)) {
        Seconds[i] = i
      }
      
      dfCpu <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(kafkaNode$V1, 48, 52))), Seconds)
      dfMemory <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(kafkaNode$V1, 53, 57))), Seconds)
      cpuUsage <- rbind(cpuUsage, dfCpu)
      memoryUsage <- rbind(memoryUsage, dfMemory)
    }
    
    names(cpuUsage) <- c("NODE","USAGE", "TIME")
    ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_line() +
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("CPU load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Kafka Servers CPU load for TPS", TPS)) +
      theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
    names(memoryUsage) <- c("NODE","USAGE","TIME")
    ggsave(paste("KAFKA", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
    
    ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_line() +
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("Memory load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Kafka Servers MEMORY load for TPS", TPS)) +
      theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("KAFKA", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
    
  }
}