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
