## ----example1-----------------------------------------------------------------
library(GetTDData)

asset.codes <- 'LTN'   # Identifier of assets 
maturity <- '010116'  # Maturity date as string (ddmmyy)
cache_folder <- paste0(tempdir(), '/TD_cache')

my.flag <- download.TD.data(asset.codes = asset.codes, 
                            dl.folder = cache_folder)

my.df <- read.TD.files(dl.folder = cache_folder)

## ----plot.prices, fig.width=7, fig.height=2.5---------------------------------
library(ggplot2)

# filter single LTN 
LTN <- my.df |>
  dplyr::filter(matur.date == as.Date("2020-01-01") )

p <- ggplot(data = LTN, 
            aes(x = as.Date(ref.date), 
                y = price.bid, 
                color = asset.code)) + 
  geom_line(size = 1) + scale_x_date() + labs(title = '', x = 'Dates')

print(p)

## ----plot.yield, fig.width=7, fig.height=2.5----------------------------------
p <- ggplot(data = LTN, 
            aes(x = as.Date(ref.date), 
                y = yield.bid, 
                color = asset.code)) + 
   geom_line(size = 1) + 
  scale_x_date() + 
  labs(title = '', 
       x = 'Dates')

print(p)


## ----example2-----------------------------------------------------------------
library(GetTDData)
library(ggplot2)

asset.codes <- 'LTN'   # Name of asset
maturity <- NULL      # = NULL, downloads all maturities

# download data
my.flag <- download.TD.data(asset.codes = asset.codes, 
                            dl.folder = cache_folder,
                            do.clean.up = F)

# reads data
my.df <- read.TD.files(dl.folder = cache_folder)

## ----example2_plots, fig.width=7, fig.height=2.5------------------------------
# plot data (prices)
p <- ggplot(data = my.df, 
            aes(x = as.Date(ref.date), y = price.bid, color = asset.code)) + 
  geom_line() + scale_x_date() + labs(title = '', x = 'Dates', y = 'Prices' )

print(p)

# plot data (yields)
p <- ggplot(data = my.df, 
            aes(x = as.Date(ref.date), y = yield.bid, color = asset.code)) + 
  geom_line() + scale_x_date() + labs(title = '', x = 'Dates', y = 'Yields' )

print(p)


