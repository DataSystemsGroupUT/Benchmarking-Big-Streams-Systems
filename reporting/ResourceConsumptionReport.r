

######################################################################################################################################
##########################                        Benchmark Resource Consumption                            ##########################
######################################################################################################################################
tps=1000
duration=600
engines <- c("flink", "kafka", "spark_dataset_3000","spark_dstream_3000")
library(dplyr)
eng=1
i=1

generateStreamServerLoadReport <- function(engines, tps, duration){
   charts <- c()
   for(i in 1:15) {
     memoryUsage= NULL
     cpuUsage= NULL
     for(eng in 1:length(engines)){
       engine = engines[eng]
       TPS = toString(tps*i)
       reportFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", sep = "")
       sourceFolder = paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/", engine, "/TPS_", TPS,"_DURATION_",toString(duration),"/", sep = "")
       #Get the stream servers cpu and memory consumption statistics
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
         dfCpu <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(streamCpu$V1, 9, 14))), SecondsCpu)
         dfMemory <- data.frame(engine, paste("Node " , x, sep=""), as.numeric(trim(substr(streamMem$V3, 2, 10)))*100/as.numeric(trim(substr(streamMem$V1, 11, 19))), SecondsMem)
         cpuUsage <- rbind(cpuUsage, dfCpu)
         memoryUsage <- rbind(memoryUsage, dfMemory)
       }
     }
     names(cpuUsage) <- c("ENGINE","NODE","USAGE", "TIME")
     names(memoryUsage) <- c("ENGINE", "NODE","USAGE","TIME")
     cpuUsage <- cpuUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))
     memoryUsage <- memoryUsage %>% group_by(ENGINE, TIME) %>% summarise(USAGE=mean(USAGE))
     
     ggplot(data=cpuUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) + 
       scale_y_continuous(breaks= pretty_breaks()) +
       geom_smooth(method="loess", se=F) + 
       guides(fill=FALSE) +
       labs(x="Time (seconds)", y="CPU load percentage",
            title=paste("", "BENCHMARK"),
            subtitle=paste("Stream Servers CPU load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 15, face = "plain"), plot.subtitle = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
     ggsave(paste("TPS",TPS,"STREAM", "CPU.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)
     
     
     ggplot(data=memoryUsage, aes(x=TIME, y=USAGE, group=ENGINE, colour=ENGINE)) + 
       geom_smooth(method="loess", se=F) + 
       scale_y_continuous(breaks= pretty_breaks()) +
       guides(fill=FALSE) +
       labs(x="Time (seconds)", y="Memory load percentage",
            title=paste(toupper(engine), "BENCHMARK"),
            subtitle=paste("Stream Servers Memory load with", toString(tps*i*10), "TPS")) +
       theme(plot.title = element_text(size = 15, face = "plain"), plot.subtitle = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
     ggsave(paste("TPS",TPS,"STREAM", "MEMMORY.pdf", sep = "_"), width = 20, height = 20, units = "cm", device = "pdf", path = reportFolder)
   }
   
}

