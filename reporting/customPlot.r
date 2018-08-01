


customPlot <- function(inputData, sxtitle, ytitle, title, subtitle, filename){
  
  ggplot(data=inputData, aes(x=TIME, y=USAGE, group=NODE, colour=NODE)) + 
    geom_smooth(method="auto", se=F) + 
    guides(fill=FALSE) +
    xlab("Seconds") + ylab("CPU load percentage") +
    ggtitle(title) +
    theme(plot.title = element_text(size = 13, face = "plain"), text = element_text(size = 12, face = "plain"))
  ggsave(filename, width = 20, height = 20, units = "cm", device = "pdf", path = sourceFolder)

}