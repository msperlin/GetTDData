<!-- badges: start -->
  [![Codecov test coverage](https://codecov.io/gh/msperlin/GetTDData/branch/master/graph/badge.svg)](https://app.codecov.io/gh/msperlin/GetTDData?branch=master)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R build (rcmdcheck)](https://github.com/msperlin/GetTDData/workflows/R-CMD-check/badge.svg)](https://github.com/msperlin/GetTDData/actions)

  <!-- badges: end -->

# Package `GetTDData`

Information regarding prices and  yields of bonds issued by the Brazilian government can be downloaded manually as excel files from the [Tesouro Direto website](https://www.tesourodireto.com.br/). However, it is painful to aggregate all of this data into something useful as the several files don't have an uniform format.

Package `GetTDData` makes the process of importing data from Tesouro direto much easier. All that you need in order to download the data is the name of the assets (LFT, LTN, NTN-C, NTN-B, NTN-B Principal, NTN-F). 


# Installation

```
# from CRAN (stable version)
install.package('GetTDData')

# from github (development version)
devtools::install_github('msperlin/GetTDData')
```

# How to use `GetTDData`

See documentation page at [https://msperlin.github.io/GetTDData/](https://msperlin.github.io/GetTDData/).
