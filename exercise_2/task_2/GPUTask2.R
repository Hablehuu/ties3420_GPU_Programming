library(ggplot2)

#Parameters
#GFLOPS
T_peak <- 1430 
#Memory bandwidth
B <- 288         

#operational intensity range
OI <- seq(0.01, 100, by = 0.1)

#intensity of for loop flops/bytes
I <- 1.1875

 
#performance
P <- OI * B

#points for arrow
point_a <- c(x = I, y = 0)
point_b <- c(x = I, y = min(1430,B*I))     

#balance point
balance_point <- c(x = 1430/288, y = 1430)


data <- data.frame(OI = OI, Performance = P)

# Plot
ggplot(data, aes(x = OI, y = Performance)) +
  geom_line(color = "blue", size = 1) +                     
  geom_hline(yintercept = T_peak, color = "red") +  
  scale_x_log10() +                                        
  scale_y_log10() +                                       
  labs(title = "Roofline Model of a GPU",
       x = "Operational Intensity (Ops/Byte)",
       y = "Performance (GFLOPS)") + 
  geom_segment(aes(x = point_a['x'], y = point_a['y'], xend = point_b['x'], yend = point_b['y']),
              arrow = arrow(length = unit(0.2, "inches")), color = "grey", size = 1) +
  annotate("path",
           x = exp(log(balance_point['x']) + 0.2 * cos(seq(0, 2 * pi, length.out = 100))),
           y = exp(log(balance_point['y']) + 0.2 * sin(seq(0, 2 * pi, length.out = 100))),
           color = "purple", size = 1) +
  theme_minimal()







