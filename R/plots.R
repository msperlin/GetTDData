#' Plot the ANBIMA Yield Curve
#'
#' Plots the yield curve data frame downloaded using \code{\link{get_yield_curve}}.
#'
#' @param df_yc A data frame or tibble returned by \code{\link{get_yield_curve}}.
#'
#' @return A \code{ggplot} object.
#' @export
#'
#' @examples
#' \dontrun{
#' df_yc <- get_yield_curve()
#' plot_yield_curve(df_yc)
#' }
plot_yield_curve <- function(df_yc) {
  if (missing(df_yc) || !is.data.frame(df_yc) || nrow(df_yc) == 0) {
    cli::cli_abort("Input `df_yc` must be a valid non-empty data frame from `get_yield_curve()`.")
  }

  current_date_str <- if ("current_date" %in% names(df_yc)) as.character(df_yc$current_date[1]) else ""

  p <- ggplot2::ggplot(df_yc, ggplot2::aes(x = .data$ref_date, y = .data$value, color = .data$type)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::facet_wrap(~ .data$type, scales = "free_y") +
    ggplot2::labs(
      title = "Brazilian Yield Curve (ANBIMA)",
      subtitle = paste("Reference Date:", current_date_str),
      x = "Maturity Date",
      y = "Rate (%)",
      color = "Curve Type"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  return(p)
}

#' Plot Tesouro Direto Time Series Data
#'
#' Plots price or yield time series trajectories for Tesouro Direto assets downloaded using \code{\link{td_get}}.
#'
#' @param df_td A data frame or tibble returned by \code{\link{td_get}}.
#' @param type Character string indicating what to plot: \code{"price"} (price_bid) or \code{"yield"} (yield_bid). Defaults to \code{"price"}.
#'
#' @return A \code{ggplot} object.
#' @export
#'
#' @examples
#' \dontrun{
#' df_td <- td_get("LTN", 2020, 2022)
#' plot_td_series(df_td, type = "price")
#' }
plot_td_series <- function(df_td, type = c("price", "yield")) {
  if (missing(df_td) || !is.data.frame(df_td) || nrow(df_td) == 0) {
    cli::cli_abort("Input `df_td` must be a valid non-empty data frame from `td_get()`.")
  }

  type <- match.arg(type)

  y_var <- if (type == "price") "price_bid" else "yield_bid"
  y_label <- if (type == "price") "Price (R$)" else "Yield / Rate"
  title_text <- if (type == "price") "Tesouro Direto Bond Prices" else "Tesouro Direto Bond Yields"

  p <- ggplot2::ggplot(df_td, ggplot2::aes(x = .data$ref_date, y = .data[[y_var]], color = .data$asset_code)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::labs(
      title = title_text,
      x = "Reference Date",
      y = y_label,
      color = "Asset Code"
    ) +
    ggplot2::theme_minimal()

  return(p)
}
