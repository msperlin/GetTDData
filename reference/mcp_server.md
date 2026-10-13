# Run a GetTDData MCP server

Starts a Model Context Protocol (MCP) server that exposes a curated set
of \`GetTDData\` functions as tools for LLM clients such as OpenCode,
Claude Desktop, Claude Code, or Positron Assistant. The suggested
package \`mcptools\` is required.

## Usage

``` r
mcp_server(
  tools = mcp_tools(),
  type = c("stdio", "http"),
  session_tools = FALSE,
  ...
)
```

## Arguments

- tools:

  Either a list of \`ellmer::tool()\` objects, or the path to an R file
  that evaluates to such a list. Defaults to the tool definitions
  shipped with the package (see \[mcp_tools()\]).

- type:

  Transport type: \`"stdio"\` (default) for clients that launch the
  process, or \`"http"\` for an HTTP server.

- session_tools:

  Logical. Whether to expose mcptools' built-in R session discovery
  tools (\`list_r_sessions\`, \`select_r_session\`). Defaults to
  \`FALSE\` because GetTDData tools run self-contained in the server
  process.

- ...:

  Further arguments passed on to \`mcptools::mcp_server()\`, such as
  \`host\` or \`port\`.

## Value

Called for its side effect of blocking the R process while the server
runs. It does not return.

## Details

Register the server with an MCP client by running \`Rscript -e
"GetTDData::mcp_server()"\`. For example, in OpenCode:

“\`json "mcp": "servers": "GetTDData": "type": "local", "command":
\["Rscript", "-e", "GetTDData::mcp_server()"\] “\`

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires the mcptools, ellmer, and jsonlite packages
GetTDData::mcp_server()
} # }
```
