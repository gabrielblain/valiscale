#' Calculate Agreement Statistics Between Observed and Estimated Values
#'
#' Calculates agreement and performance statistics for paired observed and
#' estimated values. The function is designed to work directly with the output
#' of \code{\link{aggregate_scale}}, allowing statistics to be calculated
#' overall or separately by year, season, month, or period.
#'
#' @param df A data.frame containing exactly seven columns:
#'   \code{year}, \code{season}, \code{season-year}, \code{month},
#'   \code{period}, \code{obs}, and \code{est}.
#' @param by Character. Grouping level for calculating statistics. Must be one
#'   of \code{"year"}, \code{"season"}, \code{"month"}, or \code{"period"}.
#'   If \code{NULL} (default), statistics are calculated for the complete
#'   dataset.
#' @param digits Integer. Number of decimal places to round the output
#'   statistics. Default is 2.
#'
#' @return A data.frame containing the chosen grouping column followed by:
#' \itemize{
#'   \item \code{N} — number of paired observations
#'   \item \code{ME} — Mean Error (bias; est - obs)
#'   \item \code{MAE} — Mean Absolute Error
#'   \item \code{RMSE} — Root Mean Squared Error
#'   \item \code{MaxAE} — Maximum Absolute Error
#'   \item \code{rME} — Relative Mean Error (scaled by mean observed value, %)
#'   \item \code{rMAE} — Relative Mean Absolute Error (scaled by mean observed value, %)
#'   \item \code{rRMSE} — Relative Root Mean Squared Error (scaled by mean observed value, %)
#'   \item \code{PBIAS} — Percent Bias (%)
#'   \item \code{NSE} — Nash–Sutcliffe Efficiency coefficient
#'   \item \code{d} — Willmott's Index of Agreement (original formulation)
#'   \item \code{d_mod} — Modified Willmott's Index of Agreement
#'   \item \code{R2} — Coefficient of determination (squared correlation)
#' }
#'
#' @examples
#' df <- data.frame(
#'   Date = seq(as.Date("2000-01-01"), by = "day", length.out = 9496),
#'   obs = rnorm(9496, mean = 20, sd = 3),
#'   est = rnorm(9496, mean = 20, sd = 3)
#' )
#'
#' testing_data <- aggregate_scale(df, scale = "daily", FUN = mean)
#'
#' # Overall statistics
#' agreement_stats(testing_data)
#'
#' # Statistics by year
#' agreement_stats(testing_data, by = "year")
#'
#' # Statistics by season
#' agreement_stats(testing_data, by = "season")
#'
#' # Statistics by month
#' agreement_stats(testing_data, by = "month")
#'
#' # Statistics by period
#' agreement_stats(testing_data, by = "period")
#'
#' @export
agreement_stats <- function(df, by = NULL, digits = 2) {

  # -----------------------------

  # Basic Validation

  # -----------------------------

  if (!is.data.frame(df)) {
    stop("'df' must be a data.frame.")
  }

  colnames(df) <- tolower(colnames(df))

  required_cols <- c(
    "year", "season", "season-year",
    "month", "period", "obs", "est"
  )

  if (ncol(df) != 7 || !all(required_cols %in% names(df))) {
    stop(
      "Input data.frame must contain exactly seven columns named ",
      "'year', 'season', 'season-year', 'month', 'period', 'obs', and 'est'."
    )
  }

  # -----------------------------

  # Validate Grouping Argument

  # -----------------------------

  if (!is.null(by)) {
    by <- match.arg(
      by,
      choices = c("year", "season", "month", "period")
    )
  }

  # -----------------------------

  # Validate digits

  # -----------------------------

  if (!is.numeric(digits) || length(digits) != 1 ||
      is.na(digits) || digits < 0 || digits != as.integer(digits)) {
    stop("'digits' must be a single non-negative integer.")
  }

  # -----------------------------

  # Internal Calculation Engine

  # -----------------------------

  .calc_stats <- function(x) {

    x <- stats::na.omit(x[, c("obs", "est")])

    if (nrow(x) < 2) {
      return(NULL)
    }

    obs <- x$obs
    est <- x$est

    N     <- length(obs)
    err   <- est - obs
    ME    <- mean(err)
    MAE   <- mean(abs(err))
    RMSE  <- sqrt(mean(err^2))
    MaxAE <- max(abs(err))

    mean_obs <- mean(obs)

    if (mean_obs == 0) {
      rME   <- NA_real_
      rMAE  <- NA_real_
      rRMSE <- NA_real_
    } else {
      rME   <- 100 * ME   / mean_obs
      rMAE  <- 100 * MAE  / mean_obs
      rRMSE <- 100 * RMSE / mean_obs
    }

    PBIAS <- if (sum(obs) == 0) {
      NA_real_
    } else {
      100 * sum(est - obs) / sum(obs)
    }

    R2 <- stats::cor(obs, est)^2

    den_nse <- sum((obs - mean_obs)^2)

    NSE <- if (den_nse == 0) {
      NA_real_
    } else {
      1 - sum((obs - est)^2) / den_nse
    }

    den_d <- sum(
      (abs(est - mean_obs) + abs(obs - mean_obs))^2
    )

    d <- if (den_d == 0) {
      NA_real_
    } else {
      1 - sum((obs - est)^2) / den_d
    }

    den_dm <- sum(
      abs(est - mean_obs) + abs(obs - mean_obs)
    )

    d_mod <- if (den_dm == 0) {
      NA_real_
    } else {
      1 - sum(abs(obs - est)) / den_dm
    }

    data.frame(
      N = N,
      ME = ME,
      MAE = MAE,
      RMSE = RMSE,
      MaxAE = MaxAE,
      rME = rME,
      rMAE = rMAE,
      rRMSE = rRMSE,
      PBIAS = PBIAS,
      NSE = NSE,
      d = d,
      d_mod = d_mod,
      R2 = R2
    )

  }

  # -----------------------------

  # Determine Grouping Column

  # -----------------------------

  group_cols <- if (is.null(by)) {
    character(0)
  } else {
    by
  }

  # -----------------------------

  # Aggregation Scale Safety Checks

  # -----------------------------

  seasonal_labels <- c(
    "Dec-Feb", "Mar-May", "Jun-Aug", "Sep-Nov"
  )

  if ("month" %in% names(df) &&
      any(df$month %in% seasonal_labels, na.rm = TRUE) &&
      identical(by, "month")) {

    stop(
      "Cannot calculate monthly statistics: the input data are already ",
      "aggregated to seasonal scale. Use by = 'season' instead."
    )

  }

  if ("month" %in% names(df) &&
      any(df$month == "1 to 12", na.rm = TRUE) &&
      identical(by, "month")) {

    stop(
      "Cannot calculate monthly statistics: the input data are already ",
      "aggregated to yearly scale."
    )

  }

  # -----------------------------

  # Execution Path

  # -----------------------------

  if (length(group_cols) > 0) {


    sub_sets <- split(
      df,
      df[, group_cols, drop = FALSE],
      drop = TRUE
    )

    output <- lapply(sub_sets, function(sub_df) {

      temp <- .calc_stats(sub_df)

      if (is.null(temp)) {
        return(NULL)
      }

      for (col in group_cols) {
        temp[[col]] <- sub_df[[col]][1]
      }

      temp
    })

    output <- do.call(rbind, output)

    # Sparse data safety net
    if (is.null(output) || nrow(output) == 0) {
      stop(
        "The requested grouping contains insufficient data ",
        "(fewer than 2 observations per group) to calculate ",
        "agreement statistics."
      )
    }

    stat_cols <- c(
      "N", "ME", "MAE", "RMSE", "MaxAE",
      "rME", "rMAE", "rRMSE", "PBIAS",
      "NSE", "d", "d_mod", "R2"
    )

    output <- output[
      ,
      c(group_cols, stat_cols),
      drop = FALSE
    ]

    # Order output by grouping variable
    if (identical(by, "month") &&
        all(grepl("^[0-9]+$", output$month))) {

      output <- output[
        order(as.numeric(output$month)),
        ,
        drop = FALSE
      ]

    } else {

      order_args <- lapply(
        group_cols,
        function(col) output[[col]]
      )

      output <- output[
        do.call(order, order_args),
        ,
        drop = FALSE
      ]
    }

    rownames(output) <- NULL

    # Safe base R rounding for numeric columns only
    num_cols <- sapply(output, is.numeric)

    output[num_cols] <- round(
      output[num_cols],
      digits = digits
    )

    return(output)


  } else {


    overall_out <- .calc_stats(df)

    if (!is.null(overall_out)) {

      rownames(overall_out) <- NULL

      num_cols <- sapply(
        overall_out,
        is.numeric
      )

      overall_out[num_cols] <- round(
        overall_out[num_cols],
        digits = digits
      )

    } else {

      stop(
        "Insufficient data overall (fewer than 2 observations) ",
        "to calculate agreement statistics. Use by = NULL instead."
      )
    }

    return(overall_out)


  }
}
