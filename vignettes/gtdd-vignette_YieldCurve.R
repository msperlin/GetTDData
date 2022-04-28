## -----------------------------------------------------------------------------
library(GetTDData)

df.yield <- get.yield.curve()  
str(df.yield)

## -----------------------------------------------------------------------------
library(ggplot2)

p <- ggplot(df.yield, aes(x=ref.date, y = value) ) +
  geom_line(size=1) + geom_point() + facet_grid(~type, scales = 'free') + 
  labs(title = paste0('The current Brazilian Yield Curve '),
       subtitle = paste0('Date: ', df.yield$current.date[1]))     

print(p)

