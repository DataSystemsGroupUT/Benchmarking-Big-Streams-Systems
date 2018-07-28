for(i in 1:6) {
  TPS = toString(1000*i)
  Seen = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS", TPS,"DURATION_1800/load-node01-seen.txt",sep="_"),header=F,stringsAsFactors=F,sep=',')
  Updated = read.table(paste("/Users/sahverdiyev/Desktop/EDU/THESIS/stream-benchmarking/result/flink/TPS", TPS, "DURATION_1800/load-node01-updated.txt",sep="_"),header=F,stringsAsFactors=F,sep=',')
  if (length(Seen$V1)  != length(Updated$V1)){ 
    stop("Input data set is wrong. Be sure you have selected correct collections")
  }
  print(sum(Seen$V1))
  #plot(density(Seen$V1, kernel = "gaussian", bw = "nrd0", na.rm = T),col="red", main="Kernel density estimation", xlab="time of week")
}


