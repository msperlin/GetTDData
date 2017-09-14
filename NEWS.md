### Version 1.3 (2017-09-14)
  - Added function for downloading current yield curve from Anbima
  - Fixed typos in vignettes
  - dev version now in github
  - fixed bug for names of NTN-Principal

### Version 1.2.5 (2016-11-07)
  - Added the maturities of the instruments as an extra column in the dataframe

### Version 1.2.4 (2016-08-15)
  - The package CHECK process no longer depends on the avaibility of Tesouro Direto website. All needed files are now local

### Version 1.2.3 (2016-05-22)
  - Fixed bug in html download. Now using a new function and a new algorithm to try the download 10 times before throwing an error

### Version 1.2.2 (2016-05-22)
  - The html structure of the Tesouro Website has changed and that resulted in CHECK errors in the package. This update fixed it.
  - Fixed TD names in read function (TD website is a mess!)
  - Now also using input asset.codes in read function
	
### Version 1.2.1 (2016-05-04)
	- Fixed bug in read.td.files (it was not reading data after 2012 because of change of output type given switch from xlsx:read.xlsx to readxl::read_excel)

### Version 1.2 (2016-04-29)
	- Now using readxl::read_excel, a better excel reader, FASTER and without the java requirements
	- Additional error checks
	
### Version 1.1.0 (2016-04-12)
	- Added a test for internet connection
	- Added a new option for overwriting or not the downloaded excel files (saves a lot of time for large batch downloads!)
	- Fixed typos and improved the text in the vignette
  
### Version 1.0.0 - Initial version (2016-02-10)
