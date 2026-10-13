#' Build the Model Context Protocol (MCP) tools exposed by GetTDData
#'
#' Sources the MCP tool definitions shipped with the package
#' (`inst/mcp/tools.R`) and returns them as a list of `ellmer::tool()` objects.
#' These tools wrap a curated set of `GetTDData` functions so that MCP-enabled
#' LLM clients can fetch Brazilian government bond data.
#'
#' @param path Path to an R file that, when sourced, evaluates to a list of
#'   `ellmer::tool()` objects. Defaults to the definitions shipped with the
#'   package. This argument is mainly useful for testing custom tool sets.
#'
#' @return A named list of `ellmer::tool()` objects.
#'
#' @details
#' The suggested packages `ellmer` and `jsonlite` are required. The tool set
#' currently exposes: `get_td_data()`, `get_td_current()`,
#' `get_yield_curve()`, `get_asset_info()`, and `get_td_names()`.
#'
#' @export
#' @examples
#' \dontrun{
#' # Requires the ellmer and jsonlite packages
#' tools <- mcp_tools()
#' names(tools)
#' }
mcp_tools <- function(path = system.file("mcp", "tools.R", package = "GetTDData")) {
  for (pkg in c("ellmer", "jsonlite")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(
        sprintf(
          "Package '%s' is required to build the MCP tools. Install it with install.packages('%s').",
          pkg, pkg
        ),
        call. = FALSE
      )
    }
  }

  if (!nzchar(path) || !file.exists(path)) {
    stop(
      "Could not find the MCP tool definitions shipped with GetTDData.",
      call. = FALSE
    )
  }

  tools <- source(path, local = new.env(parent = globalenv()))$value

  if (!is.list(tools) || !all(vapply(tools, inherits, logical(1), what = "ellmer::ToolDef"))) {
    stop("The MCP tools file must evaluate to a list of ellmer::tool() objects.", call. = FALSE)
  }

  tools
}

#' Run a GetTDData MCP server
#'
#' Starts a Model Context Protocol (MCP) server that exposes a curated set of
#' `GetTDData` functions as tools for LLM clients such as OpenCode, Claude
#' Desktop, Claude Code, or Positron Assistant. The suggested package
#' `mcptools` is required.
#'
#' @param tools Either a list of `ellmer::tool()` objects, or the path to an R
#'   file that evaluates to such a list. Defaults to the tool definitions
#'   shipped with the package (see [mcp_tools()]).
#' @param type Transport type: `"stdio"` (default) for clients that launch the
#'   process, or `"http"` for an HTTP server.
#' @param session_tools Logical. Whether to expose mcptools' built-in R session
#'   discovery tools (`list_r_sessions`, `select_r_session`). Defaults to
#'   `FALSE` because GetTDData tools run self-contained in the server process.
#' @param ... Further arguments passed on to `mcptools::mcp_server()`, such as
#'   `host` or `port`.
#'
#' @return Called for its side effect of blocking the R process while the
#'   server runs. It does not return.
#'
#' @details
#' Register the server with an MCP client by running
#' `Rscript -e "GetTDData::mcp_server()"`. For example, in OpenCode:
#'
#' ```json
#' {
#'   "mcp": {
#'     "servers": {
#'       "GetTDData": {
#'         "type": "local",
#'         "command": ["Rscript", "-e", "GetTDData::mcp_server()"]
#'       }
#'     }
#'   }
#' }
#' ```
#'
#' @export
#' @examples
#' \dontrun{
#' # Requires the mcptools, ellmer, and jsonlite packages
#' GetTDData::mcp_server()
#' }
mcp_server <- function(tools = mcp_tools(),
                       type = c("stdio", "http"),
                       session_tools = FALSE,
                       ...) {
  if (!requireNamespace("mcptools", quietly = TRUE)) {
    stop(
      "Package 'mcptools' is required to run the MCP server. Install it with install.packages('mcptools').",
      call. = FALSE
    )
  }

  mcptools::mcp_server(
    tools = tools,
    type = match.arg(type),
    session_tools = session_tools,
    ...
  )
}
