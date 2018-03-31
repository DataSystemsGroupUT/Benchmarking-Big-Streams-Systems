
library(ggplot2)
library(scales)


trim <- function (x) gsub("^\\s+|\\s+$", "", x)
######################################################################################################################################
##########################                                                                                  ##########################
##########################                                                                                  ##########################
##########################                             Flink Benchmark Result                               ##########################
##########################                                                                                  ##########################
##########################                                                                                  ##########################
######################################################################################################################################
result = NULL
for(i in 1:4) {
  TPS = toString(1000*i)
  Seen = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS", TPS,"DURATION_1800/redis-seen.txt",sep="_"),header=F,stringsAsFactors=F,sep=',')
  Updated = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS", TPS, "DURATION_1800/redis-updated.txt",sep="_"),header=F,stringsAsFactors=F,sep=',')
  
  SumProceed = c()
  for(i in 1:length(Seen$V1)) {
    SumProceed[i] = sum(Seen$V1[1:i])
  }
  df <- data.frame(TPS, Seen$V1, round(Updated$V1, digits=-2), round(SumProceed*100/sum(Seen$V1),digits=0))
  result <- rbind(result, df)
  
  if (length(Seen$V1)  != length(Updated$V1)){ 
    stop("Input data set is wrong. Be sure you have selected correct collections")
  }
}
names(result) <- c("TPS","Seen","Throughput", "Percentile")
ggplot(data=result, aes(x=Percentile, y=Throughput, group=TPS, colour=TPS)) + 
  geom_line() +
  guides(fill=FALSE) +
  xlab("Percentage of Completed Tuple") + ylab("Window Throughput ms ") +
  ggtitle("Apache Flink Benchmark") +
  theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
ggsave(paste("FLINK", "BENCHMARK.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf")

######################################################################################################################################
##########################                  Flink Benchmark Kafka Server Load                               ##########################
######################################################################################################################################
for(i in 1:4) {
  TPS = toString(1000*i)
  memoryUsage= NULL
  cpuUsage= NULL
  for(x in 1:4) {
    kafkaNode = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS_", TPS,"_DURATION_1800/kafka-node0", x,".process",sep=""),header=F,stringsAsFactors=F,sep=',')

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
    ggtitle(paste("FLINK BENCHMARK Kafka Servers CPU load for TPS", TPS)) +
    theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
  names(memoryUsage) <- c("NODE","USAGE","TIME")
  ggsave(paste("FLINK", TPS, "KAFKA", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf")
  
  ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
    geom_line() +
    guides(fill=FALSE) +
    xlab("Seconds") + ylab("Memory load percentage") +
    ggtitle(paste("FLINK BENCHMARK Kafka Servers MEMORY load for TPS", TPS)) +
    theme(plot.title = element_text(size = 15, face = "plain"), text = element_text(size = 12, face = "plain"))
   ggsave(paste("FLINK", TPS, "KAFKA", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf")

}



######################################################################################################################################
##########################                  Flink Benchmark Stream Server Load                              ##########################
######################################################################################################################################

x=1
streamPid = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS_", TPS,"_DURATION_1800/stream-node0", x,".pid",sep=""),header=F,stringsAsFactors=F,sep=',')
print(streamPid)
dfPid <- data.frame(paste("Stream 0" , x, sep=""), trim(substr(streamPid$V1, 1, 24)))

for(i in 1:4) {
  TPS = toString(1000*i)
  memoryUsage= NULL
  cpuUsage= NULL
  for(x in 1:8) {
    kafkaNode = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS_", TPS,"_DURATION_1800/stream-node0", x,".process",sep=""),header=F,stringsAsFactors=F,sep=',')
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
    ggtitle(paste("FLINK BENCHMARK Stream Servers CPU load for TPS", TPS)) +
    theme(plot.title = element_text(size = 7, face = "plain"), text = element_text(size = 7, face = "plain"))
    ggsave(paste("FLINK", TPS, "STREAM", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf")
  
  names(memoryUsage) <- c("NODE","USAGE","TIME")
  ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
    geom_line() +
    guides(fill=FALSE) +
    xlab("Seconds") + ylab("Memory load percentage") +
    ggtitle(paste("FLINK BENCHMARK Stream Servers MEMORY load for TPS", TPS)) +
    theme(plot.title = element_text(size = 7, face = "plain"), text = element_text(size = 7, face = "plain"))
    ggsave(paste("FLINK", TPS, "STREAM", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf")
}



