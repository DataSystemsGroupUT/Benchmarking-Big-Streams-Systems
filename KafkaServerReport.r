

######################################################################################################################################
##########################                        Benchmark Kafka Server Load                               ##########################
######################################################################################################################################
generateKafkaServerLoadReport <- function(engine, tps, duration){
  for(i in 1:3) {
    TPS = toString(tps*i)
    memoryUsage= NULL
    cpuUsage= NULL
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
    for(x in 1:4) {
      kafkaCpu = read.table(paste(sourceFolder, "kafka-node0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
      kafkaMem = read.table(paste(sourceFolder, "kafka-node0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')
      
      SecondsCpu = c()
      for(i in 1:length(kafkaCpu$V1)) {
        SecondsCpu[i] = i
      }
      
      SecondsMem = c()
      for(i in 1:length(kafkaMem$V1)) {
        SecondsMem[i] = i
      }
      
      dfCpu <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(kafkaCpu$V1, 9, 14))), SecondsCpu)
      dfMemory <- data.frame(paste("Node 0" , x, sep=""), as.numeric(trim(substr(kafkaMem$V3, 2, 10)))*100/as.numeric(trim(substr(kafkaMem$V1, 11, 19))), SecondsMem)
      cpuUsage <- rbind(cpuUsage, dfCpu)
      memoryUsage <- rbind(memoryUsage, dfMemory)
    }
    
    names(cpuUsage) <- c("NODE","USAGE", "TIME")
    ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_smooth(method="auto", se=F) + 
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("CPU load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Kafka Servers CPU load for TPS", TPS)) +
      theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
    names(memoryUsage) <- c("NODE","USAGE","TIME")
    ggsave(paste("KAFKA", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
    
    ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_smooth(method="auto", se=F) + 
      guides(fill=FALSE) +
      xlab("Seconds") + ylab("Memory load percentage") +
      ggtitle(paste(toupper(engine), "BENCHMARK Kafka Servers MEMORY load for TPS", TPS)) +
      theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("KAFKA", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
  }
}
