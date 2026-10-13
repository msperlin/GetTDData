# Build the Model Context Protocol (MCP) tools exposed by GetTDData

Sources the MCP tool definitions shipped with the package
(\`inst/mcp/tools.R\`) and returns them as a list of \`ellmer::tool()\`
objects. These tools wrap a curated set of \`GetTDData\` functions so
that MCP-enabled LLM clients can fetch Brazilian government bond data.

## Usage

``` r
mcp_tools(path = system.file("mcp", "tools.R", package = "GetTDData"))
```

## Arguments

- path:

  Path to an R file that, when sourced, evaluates to a list of
  \`ellmer::tool()\` objects. Defaults to the definitions shipped with
  the package. This argument is mainly useful for testing custom tool
  sets.

## Value

A named list of \`ellmer::tool()\` objects.

## Details

The suggested packages \`ellmer\` and \`jsonlite\` are required. The
tool set currently exposes: \`get_td_data()\`, \`get_td_current()\`,
\`get_yield_curve()\`, \`get_asset_info()\`, and \`get_td_names()\`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires the ellmer and jsonlite packages
tools <- mcp_tools()
names(tools)
} # }
```
