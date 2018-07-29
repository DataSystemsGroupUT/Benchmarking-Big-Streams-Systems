

######################################################################################################################################
##########################                        Benchmark Stream Server Load                              ##########################
######################################################################################################################################

generateStreamServerLoadReport <- function(engine, tps, duration){
  for(i in 1:15) {
    TPS = toString(tps*i)
    memoryUsage= NULL
    cpuUsage= NULL
    sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
    for(x in 1:10) {
      streamCpu = read.table(paste(sourceFolder, "stream-node-0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
      streamMem = read.table(paste(sourceFolder, "stream-node-0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')
      
      SecondsCpu = c()
      for(c in 1:length(streamCpu$V1)) {
        SecondsCpu[c] = c
      }
      
      SecondsMem = c()
      for(m in 1:length(streamMem$V1)) {
        SecondsMem[m] = m
      }
      dfCpu <- data.frame(paste("Node " , x, sep=""), as.numeric(trim(substr(streamCpu$V1, 9, 14))), SecondsCpu)
      dfMemory <- data.frame(paste("Node " , x, sep=""), as.numeric(trim(substr(streamMem$V3, 2, 10)))*100/as.numeric(trim(substr(streamMem$V1, 11, 19))), SecondsMem)
      cpuUsage <- rbind(cpuUsage, dfCpu)
      memoryUsage <- rbind(memoryUsage, dfMemory)
    }
    
    names(cpuUsage) <- c("NODE","USAGE", "TIME")
    ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      scale_y_continuous(breaks= pretty_breaks()) +
      geom_smooth(method="loess", se=F) + 
      guides(fill=FALSE) +
      labs(x="Seconds", y="CPU load percentage",
           title=paste(toupper(engine), "BENCHMARK"),
           subtitle=paste("Stream Servers CPU load with", toString(tps*i*10), "TPS"))
      theme(plot.title = element_text(size = 15, face = "plain"), plot.subtitle = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("STREAM", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
    
    names(memoryUsage) <- c("NODE","USAGE","TIME")
    ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
      geom_smooth(method="loess", se=F) + 
      scale_y_continuous(breaks= pretty_breaks()) +
      guides(fill=FALSE) +
      labs(x="Seconds", y="Memory load percentage",
           title=paste(toupper(engine), "BENCHMARK"),
           subtitle=paste("Stream Servers Memory load with", toString(tps*i*10), "TPS"))
      theme(plot.title = element_text(size = 15, face = "plain"), plot.subtitle = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
    ggsave(paste("STREAM", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)
  }
}

