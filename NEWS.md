## Version 1.7.0 (2026-08-29)
  - restored and fixed `td_get_current()` to reliably fetch daily current prices and yields from Tesouro Direto using current-year asset files
  - added `get_asset_info()` helper function providing bond metadata (indexer, coupon structure, descriptions)
  - added visualization functions `plot_yield_curve()` and `plot_td_series()` built on `ggplot2`
  - added `.rds` file caching for parsed Excel files to accelerate data loading on repeat reads
  - added option for user-persistent caching in `get_cache_folder()` via `tools::R_user_dir` or `options(GetTDData.persistent_cache = TRUE)`
  - standardized all function outputs (`td_get()`, `get_yield_curve()`, `td_get_current()`) to return `tibble` data frames (`tbl_df`)
  - updated `get_td_names()` with support for `NTN-B1` (covering RendA+ and Educa+ instruments) and optional `online` CDN check
  - fixed dead `return(TRUE)` statement in `td_get()`
  - guarded `covr::in_covr()` checks in test suite to prevent test failures when `covr` package is missing

## Version 1.6.0 (2026-06-04)
  - implemented parallel file downloading using `curl::multi_download` to speed up asset fetching
  - implemented safe parallel sheet parsing using socket clusters (`makeCluster` and `parLapply`), improving read speed and preventing C++ fork deadlocks
  - optimized sheet-reading loop by accumulating data frames in a list and calling `bind_rows` once
  - vectorized date parsing in `td_get` to avoid row-by-row `sapply` calls
  - renamed `get.yield.curve()` to `get_yield_curve()` and provided a deprecated dot-case wrapper for backward compatibility
  - removed unused package dependency `purrr` from DESCRIPTION Imports
  - removed unused package dependency `lubridate` from DESCRIPTION Suggests and replaced with base R equivalents in tests
  - converted all internal dot-case variables and column names (e.g. `n.biz.days`, `ref.date`, `current.date`, `possible.names`) to snake_case
  - fixed and corrected roxygen2 documentation inconsistency details for parameters and return values

## Version 1.5.7 (2025-05-19)
  - removed use of pkg humanize (will be removed from cran)

## Version 1.5.6 (2024-08-20)
  - fixed bug at td_get_current(), the api endpoint is no longer available. 
  
## Version 1.5.5 (2024-04-11)
  - added td_get_current(), for fetching current TD prices from the website.

## Version 1.5.4 (2023-05-15)
  - fixed issue with CRAN check. The vignette could fail in CHECK. The vignettes were deleted and the content is  now part of Readme.Rmd file, which compiles locally.
  - set dependency for R > 4.1.0
  
## Version 1.5.3 (2023-01-24)
  - deprecated functions download.TD.data() and read.TD.files(). Both are replaced by td_get()
  
## Version 1.5.2 (2023-01-01)
  - it now fails gracefuly when download of files fails.
  
## Version 1.5.1 (2022-05-11)
  - implemented change for bizdays::holidaysANBIMA (see [issue 10](https://github.com/msperlin/GetTDData/issues/10))
  
## Version 1.5.0 (2022-04-28)
  - improved github actions by adding codecov, pkgdown and LICENSE
  - added new tests and functions
  - removed arguments "maturity" and "asset.codes" from `read.TD.files` function

## Version 1.4.5 (2022-04-06)
  - Fixed issue in download related to product NTN-principal [issue #8](https://github.com/msperlin/GetTDData/issues/8)
  - removed "Date" from DESCRIPTION file (seems to be standard now)
  - increases min R version in DESCRIPTION to 4.0.0
  - improved github actions by adding codecov and pkgdown

## Version 1.4.4 (2022-03-02)
  - Fixed issue in cran check for oldrel (use of new pipeline operator, which is not available prior to R < 4.1)

## Version 1.4.3 (2022-02-18)
  - Major change in urls from Tesouro Direto (See [issue #5](https://github.com/msperlin/GetTDData/pull/5/))
  - Fixed issue with get.yield.curve() 
  - Fixed issue with yields equal to 0 (see [issue #3](https://github.com/msperlin/GetTDData/issues/3/))
  
## Version 1.4.2 (2019-10-01)
  - Found an alternative address from Anbima. (see [issue #1](https://github.com/msperlin/GetTDData/issues/1/))
  
## Version 1.4.1 (2019-07-11)
  - Fixed bug in yield function (anbima site is down...). Need to find an alternative.

## Version 1.4 (2019-04-02)
  - Fixed bug in name importing of spreadsheets
  - Prices and yield are now cleaned (no values equal to zero)
  
## Version 1.3 (2017-09-14)
  - Added function for downloading current yield curve from Anbima
  - Fixed typos in vignettes
  - dev version now in github
  - fixed bug for names of NTN-Principal

## Version 1.2.5 (2016-11-07)
  - Added the maturities of the instruments as an extra column in the dataframe

## Version 1.2.4 (2016-08-15)
  - The package CHECK process no longer depends on the avaibility of Tesouro Direto website. All needed files are now local

## Version 1.2.3 (2016-05-22)
  - Fixed bug in html download. Now using a new function and a new algorithm to try the download 10 times before throwing an error

## Version 1.2.2 (2016-05-22)
  - The html structure of the Tesouro Website has changed and that resulted in CHECK errors in the package. This update fixed it.
  - Fixed TD names in read function (TD website is a mess!)
  - Now also using input asset.codes in read function
	
## Version 1.2.1 (2016-05-04)
	- Fixed bug in read.td.files (it was not reading data after 2012 because of change of output type given switch from xlsx:read.xlsx to readxl::read_excel)

## Version 1.2 (2016-04-29)
	- Now using readxl::read_excel, a better excel reader, FASTER and without the java requirements
	- Additional error checks
	
## Version 1.1.0 (2016-04-12)
	- Added a test for internet connection
	- Added a new option for overwriting or not the downloaded excel files (saves a lot of time for large batch downloads!)
	- Fixed typos and improved the text in the vignette
  
## Version 1.0.0 - Initial version (2016-02-10)
