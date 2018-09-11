######################################################################################################################################
##########################                        Benchmark Resource Consumption                            ##########################
######################################################################################################################################

generateResourceConsumptionReport <- function(engines, tps, duration, tps_count){
   for(i in 1:tps_count) {
     memoryUsage= NULL
     cpuUsage= NULL

     kafkaMemoryUsage= NULL
     kafkaCpuUsage= NULL
     
     for(eng in 1:length(engines)){
       engine = engines[eng]
       TPS = toString(tps*i)
       reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", sep = "")
       sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
       #Get the stream servers cpu and memory consumption statistics
       for(x in 1:10) {
         streamCpu = read.table(paste(sourceFolder, "stream-node-0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
         streamMem = read.table(paste(sourceFolder, "stream-node-0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')

         SecondsCpu <- 1:length(streamCpu$V1)
         SecondsMem <- 1:length(streamMem$V1)

         dfCpu <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(streamCpu$V1, 9, 14))), SecondsCpu)
         dfMemory <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(streamMem$V3, 2, 10)))*100/as.numeric(trim(substr(streamMem$V1, 11, 19))), SecondsMem)
         names(dfCpu) <- c("ENGINE","NODE","USAGE", "TIME")
         names(dfMemory) <- c("ENGINE","NODE","USAGE", "TIME")
         cpuUsage <- rbind(cpuUsage, dfCpu)
         memoryUsage <- rbind(memoryUsage, dfMemory)
       }
       #Get the kafka servers cpu and memory consumption statistics
       for(x in 1:5) {
         kafkaCpu = read.table(paste(sourceFolder, "kafka-node-0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
         kafkaMem = read.table(paste(sourceFolder, "kafka-node-0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')

         SecondsCpu <- 1:length(kafkaCpu$V1)
         SecondsMem <- 1:length(kafkaMem$V1)

         dfCpu <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(kafkaCpu$V1, 9, 14))), SecondsCpu)
         dfMemory <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(kafkaMem$V3, 2, 10)))*100/as.numeric(trim(substr(kafkaMem$V1, 11, 19))), SecondsMem)
         names(dfCpu) <- c("ENGINE","NODE","USAGE", "TIME")
         names(dfMemory) <- c("ENGINE","NODE","USAGE", "TIME")
         kafkaCpuUsage <- rbind(kafkaCpuUsage, dfCpu)
         kafkaMemoryUsage <- rbind(kafkaMemoryUsage, dfMemory)
       }
     }

     names(cpuUsage) <- c("ENGINE","NODE","USAGE", "TIME")
     names(memoryUsage) <- c("ENGINE", "NODE","USAGE","TIME")
     cpuUsage <- cpuUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))
     memoryUsage <- memoryUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))

     names(kafkaCpuUsage) <- c("ENGINE","NODE","USAGE", "TIME")
     names(kafkaMemoryUsage) <- c("ENGINE", "NODE","USAGE","TIME")
     kafkaCpuUsage <- kafkaCpuUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))
     kafkaMemoryUsage <- kafkaMemoryUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))
     
     
     p1 <- ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) +
       scale_y_continuous(breaks= pretty_breaks()) +
       geom_smooth(method="loess", se=F, size=0.5) +
       guides(fill=FALSE) +
       labs(x="Time (seconds)", y="CPU load percentage") +
            #subtitle=paste("Stream Servers CPU load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 8, face = "plain"),
             plot.subtitle = element_text(size = 7, face = "plain"),
             text = element_text(size = 6, face = "plain"),
             legend.position="none")

     p2 <- ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) +
       geom_smooth(method="loess", se=F, size=0.5) +
       scale_y_continuous(breaks= pretty_breaks()) +
       guides(fill=FALSE) +
       labs(x="Time (seconds)", y="Memory load percentage") +
            #subtitle=paste("Stream Servers Memory load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 8, face = "plain"),
             plot.subtitle = element_text(size = 7, face = "plain"),
             text = element_text(size = 6, face = "plain"),
             legend.position="none")
     
     p3 <- ggplot(data=kafkaCpuUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) +
       scale_y_continuous(breaks= pretty_breaks()) +
       geom_smooth(method="loess", se=F, size=0.5) +
       guides(fill=FALSE, size=1) +
       labs(x="Time (seconds)", y="CPU load percentage") +
            #subtitle=paste("Kafka Servers CPU load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 8, face = "plain"),
             plot.subtitle = element_text(size = 7, face = "plain"),
             text = element_text(size = 6, face = "plain"),
             legend.position="none")
     
     p4 <- ggplot(data=kafkaMemoryUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) +
       geom_smooth(method="loess", se=F, size=0.5) +
       scale_y_continuous(breaks= pretty_breaks()) +
       guides(fill=FALSE, size=1) +
       labs(x="Time (seconds)", y="Memory load percentage") +
            #subtitle=paste("Kafka Servers Memory load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 8, face = "plain"),
             plot.subtitle = element_text(size = 7, face = "plain"),
             text = element_text(size = 6, face = "plain"),
             legend.justification = c(1, 0), 
             legend.background = element_rect(fill=alpha('white', 0.4)),
             legend.position = c(1, 0),
             legend.key.height=unit(0.7,"line"),
             legend.key.width=unit(0.5,"line"),
             legend.box.margin=margin(c(3,3,3,3)),
             legend.text=element_text(size=rel(1.0)))
     pdf(paste(reportFolder, "TPS_",TPS,"_RESOURCE_LOAD", ".pdf", sep = ""), width = 6, height = 6)
     multiplot(p1, p2, p3, p4, cols = 2)
     dev.off()
   }

}


generateResourceConsumptionReportByTps <- function(engine, tps, duration, tps_count){
    memoryUsage= NULL
    cpuUsage= NULL
  
    kafkaMemoryUsage= NULL
    kafkaCpuUsage= NULL
    for(i in 1:tps_count) {
  
      TPS = toString(tps*i)
      reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/", sep = "")
      sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
      #Get the stream servers cpu and memory consumption statistics
      for(x in 1:10) {
        streamCpu = read.table(paste(sourceFolder, "stream-node-0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
        streamMem = read.table(paste(sourceFolder, "stream-node-0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')
        
        SecondsCpu <- 1:length(streamCpu$V1)
        SecondsMem <- 1:length(streamMem$V1)
        
        dfCpu <- data.frame(engine, TPS, as.numeric(trim(substr(streamCpu$V1, 9, 14))), SecondsCpu)
        dfMemory <- data.frame(engine, TPS, as.numeric(trim(substr(streamMem$V3, 2, 10)))*100/as.numeric(trim(substr(streamMem$V1, 11, 19))), SecondsMem)
        names(dfCpu) <- c("ENGINE","TPS","USAGE", "TIME")
        names(dfMemory) <- c("ENGINE","TPS","USAGE", "TIME")
        cpuUsage <- rbind(cpuUsage, dfCpu)
        memoryUsage <- rbind(memoryUsage, dfMemory)
      }
      #Get the kafka servers cpu and memory consumption statistics
      for(x in 1:5) {
        kafkaCpu = read.table(paste(sourceFolder, "kafka-node-0", x,".cpu",sep=""),header=F,stringsAsFactors=F,sep=',')
        kafkaMem = read.table(paste(sourceFolder, "kafka-node-0", x,".mem",sep=""),header=F,stringsAsFactors=F,sep=',')
        
        SecondsCpu <- 1:length(kafkaCpu$V1)
        SecondsMem <- 1:length(kafkaMem$V1)
        
        dfCpu <- data.frame(engine, TPS, as.numeric(trim(substr(kafkaCpu$V1, 9, 14))), SecondsCpu)
        dfMemory <- data.frame(engine, TPS, as.numeric(trim(substr(kafkaMem$V3, 2, 10)))*100/as.numeric(trim(substr(kafkaMem$V1, 11, 19))), SecondsMem)
        names(dfCpu) <- c("ENGINE","TPS","USAGE", "TIME")
        names(dfMemory) <- c("ENGINE","TPS","USAGE", "TIME")
        kafkaCpuUsage <- rbind(kafkaCpuUsage, dfCpu)
        kafkaMemoryUsage <- rbind(kafkaMemoryUsage, dfMemory)
      }
    }
    names(cpuUsage) <- c("ENGINE","TPS","USAGE", "TIME")
    names(memoryUsage) <- c("ENGINE", "TPS","USAGE","TIME")
    cpuUsage <- cpuUsage %>% group_by(TPS, TIME) %>% summarise(USAGE=mean(USAGE))
    memoryUsage <- memoryUsage %>% group_by(TPS, TIME) %>% summarise(USAGE=mean(USAGE))
    
    names(kafkaCpuUsage) <- c("ENGINE","TPS","USAGE", "TIME")
    names(kafkaMemoryUsage) <- c("ENGINE", "TPS","USAGE","TIME")
    kafkaCpuUsage <- kafkaCpuUsage %>% group_by(TPS, TIME) %>% summarise(USAGE=mean(USAGE))
    kafkaMemoryUsage <- kafkaMemoryUsage %>% group_by(TPS, TIME) %>% summarise(USAGE=mean(USAGE))
    p1 <- ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=TPS, colour=TPS)) +
      scale_y_continuous(breaks= pretty_breaks()) +
      geom_smooth(method="loess", se=F, size=0.5) +
      guides(fill=FALSE) +
      labs(x="Time (seconds)", y="CPU load percentage") +
           #subtitle=paste("Stream Servers CPU load with", toString(tps*i*10), "TPS")) +
      theme(plot.title = element_text(size = 8, face = "plain"),
            plot.subtitle = element_text(size = 7, face = "plain"),
            text = element_text(size = 6, face = "plain"),
            legend.justification = c(1, 0), 
            legend.position = c(1, 0),
            legend.key.height=unit(0.5,"line"),
            legend.key.width=unit(0.5,"line"),
            legend.box.margin=margin(c(3,3,3,3)),
            legend.text=element_text(size=rel(0.5)))
    
    p2 <- ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=TPS, colour=TPS)) +
      geom_smooth(method="loess", se=F, size=0.5) +
      scale_y_continuous(breaks= pretty_breaks()) +
      guides(fill=FALSE) +
      labs(x="Time (seconds)", y="Memory load percentage") +
           #subtitle=paste("Stream Servers Memory load with", toString(tps*i*10), "TPS")) +
      theme(plot.title = element_text(size = 8, face = "plain"),
            plot.subtitle = element_text(size = 7, face = "plain"),
            text = element_text(size = 6, face = "plain"),
            legend.justification = c(1, 0), 
            legend.position = c(1, 0),
            legend.key.height=unit(0.5,"line"),
            legend.key.width=unit(0.5,"line"),
            legend.box.margin=margin(c(3,3,3,3)),
            legend.text=element_text(size=rel(0.5)))
    
    p3 <- ggplot(data=kafkaCpuUsage, aes(x=TIME, y=USAGE, group=TPS, colour=TPS)) +
      scale_y_continuous(breaks= pretty_breaks()) +
      geom_smooth(method="loess", se=F, size=0.5) +
      guides(fill=FALSE, size=1) +
      labs(x="Time (seconds)", y="CPU load percentage") +
           #subtitle=paste("Kafka Servers CPU load with", toString(tps*i*10), "TPS")) +
      theme(plot.title = element_text(size = 8, face = "plain"),
            plot.subtitle = element_text(size = 7, face = "plain"),
            text = element_text(size = 6, face = "plain"),
            legend.justification = c(1, 0), 
            legend.position = c(1, 0),
            legend.key.height=unit(0.5,"line"),
            legend.key.width=unit(0.5,"line"),
            legend.box.margin=margin(c(3,3,3,3)),
            legend.text=element_text(size=rel(0.5)))
    
    p4 <- ggplot(data=kafkaMemoryUsage, aes(x=TIME, y=USAGE, group=TPS, colour=TPS)) +
      geom_smooth(method="loess", se=F, size=0.5) +
      scale_y_continuous(breaks= pretty_breaks()) +
      guides(fill=FALSE, size=1) +
      labs(x="Time (seconds)", y="Memory load percentage") +
           #subtitle=paste("Kafka Servers Memory load with", toString(tps*i*10), "TPS")) +
      theme(plot.title = element_text(size = 8, face = "plain"),
            plot.subtitle = element_text(size = 7, face = "plain"),
            text = element_text(size = 6, face = "plain"),
            legend.justification = c(1, 0), 
            legend.position = c(1, 0),
            legend.key.height=unit(0.5,"line"),
            legend.key.width=unit(0.5,"line"),
            legend.box.margin=margin(c(3,3,3,3)),
            legend.text=element_text(size=rel(0.5)))
    pdf(paste(reportFolder, "TPS_",TPS,"_RESOURCE_LOAD", ".pdf", sep = ""), width = 6, height = 6)
    multiplot(p1, p2, p3, p4, cols = 2)
    dev.off()
}

