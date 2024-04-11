# global file set up for removing CRAN check messages
# "no visible binding for global variable"
# source: https://community.rstudio.com/t/how-to-solve-no-visible-binding-
#         for-global-variable-note/28887
my_globals <- c(
  "anulRedRate", "maturity", "minRedQty",
  "minRedVal", "min_qtd", "min_value", "mtrtyDt",
  "name", "nm", "price", "untrRedVal", "annual_ret"
)

utils::globalVariables(my_globals)
