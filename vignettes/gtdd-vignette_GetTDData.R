## ----example1-----------------------------------------------------------------
library(GetTDData)

assets <- 'LTN'   # Identifier of assets 
first_year <- 2020
last_year <- 2022

df_td <- td_get(assets,
                first_year,
                last_year)

## ----plot.prices, fig.width=7, fig.height=2.5---------------------------------
library(ggplot2)
library(dplyr)

# filter  LTN 
my_asset_code <- "LTN 010123"

LTN <- df_td %>%
  filter(asset_code  ==  my_asset_code)

p <- ggplot(data = LTN, 
            aes(x = as.Date(ref_date), 
                y = price_bid, 
                color = asset_code)) + 
  geom_line(size = 1) + scale_x_date() + labs(title = '', x = 'Dates')

print(p)

## ----plot.yield, fig.width=7, fig.height=2.5----------------------------------
p <- ggplot(data = LTN, 
            aes(x = as.Date(ref_date), 
                y = yield_bid, 
                color = asset_code)) + 
  geom_line(linewidth = 1) + 
  scale_x_date() + 
  labs(title = '', 
       x = 'Dates')

print(p)

## ----example2_plots, fig.width=7, fig.height=2.5------------------------------
# plot data (prices)
p <- ggplot(data = df_td, 
            aes(x = as.Date(ref_date), 
                y = price_bid, 
                color = asset_code)) + 
  geom_line() + 
  scale_x_date() + 
  labs(title = '', x = 'Dates', y = 'Prices' )

print(p)

# plot data (yields)
p <- ggplot(data = df_td, 
            aes(x = as.Date(ref_date), y = yield_bid, color = asset_code)) + 
  geom_line() + 
  scale_x_date() + 
  labs(title = '', x = 'Dates', y = 'Yields' )

print(p)


