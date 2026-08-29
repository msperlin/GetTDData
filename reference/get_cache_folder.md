# Returns the cache directory path

Returns the cache directory path

## Usage

``` r
get_cache_folder(persistent = getOption("GetTDData.persistent_cache", FALSE))
```

## Arguments

- persistent:

  Logical. If \`TRUE\`, uses a user-persistent directory via
  \`tools::R_user_dir\`. If \`FALSE\`, defaults to session temporary
  directory. Can also be set globally via
  \`options(GetTDData.persistent_cache = TRUE)\`. Defaults to \`FALSE\`.

## Value

A character string representing the folder path.

## Examples

``` r
get_cache_folder()
#> /tmp/RtmpzTY1yQ/td-files
```
