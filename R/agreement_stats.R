#' Calculate Agreement Statistics Between Observed and Estimated Values
#'
#' Calculates agreement and performance statistics for paired observed and
#' estimated values. The function is designed to work directly with the output
#' of \code{\link{aggregate_scale}}, allowing tracking across years, months, periods,
#' or any multi-variate combination of them.
#'
#' @param df A data.frame containing at least the columns \code{obs} and \code{est}.
#' @param by_year Logical. If TRUE, statistics are calculated separately for
#'   each year. Default is FALSE.
#' @param by_season Logical. If TRUE, statistics are calculated separately for
#'   each season. Default is FALSE.
#' @param by_month Logical. If TRUE, statistics are calculated separately for
#'   each month. Default is FALSE.
#' @param by_period Logical. If TRUE, statistics are calculated separately for
#'  each period. Default is FALSE.
#' @param digits Integer. Number of decimal places to round the output statistics. Default is 2.
#'
#' @return A data.frame containing the chosen grouping columns followed by:
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
#'   \item \code{d} — Willmott’s Index of Agreement (original formulation)
#'   \item \code{d_mod} — Modified Willmott’s Index of Agreement
#'   \item \code{R2} — Coefficient of determination (squared correlation)
#' }
#'
#' @export
agreement_stats <- function(df, by_year = FALSE,
                            by_season = FALSE,
                            by_month = FALSE,
                            by_period = FALSE,
                            digits = 2) {

  # -----------------------------
  # Basic Validation
  # -----------------------------
  if (!is.data.frame(df)) {
    stop("'df' must be a data.frame.")
  }

  colnames(df) <- tolower(colnames(df))
  req_cols <- colnames(df)
  if (!all(req_cols %in% names(df)) || ncol(df) != 7)
    stop("Input data.frame must contain exactly seven columns named
         'year', 'season', 'season-year', 'month', 'period', obs', 'est'.")

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
      rME   <- 100 * ME    / mean_obs
      rMAE  <- 100 * MAE   / mean_obs
      rRMSE <- 100 * RMSE  / mean_obs
    }

    pbias <- if (sum(obs) == 0) {
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

    den_d <- sum((abs(est - mean_obs) + abs(obs - mean_obs))^2)
    d <- if (den_d == 0) {
      NA_real_
    } else {
      1 - sum((obs - est)^2) / den_d
    }

    den_dm <- sum(abs(est - mean_obs) + abs(obs - mean_obs))
    d_mod <- if (den_dm == 0) {
      NA_real_
    } else {
      1 - sum(abs(obs - est)) / den_dm
    }

    data.frame(
      N = N, ME = ME, MAE = MAE, RMSE = RMSE, MaxAE = MaxAE,
      rME = rME, rMAE = rMAE, rRMSE = rRMSE, PBIAS = pbias,
      NSE = NSE, d = d, d_mod = d_mod, R2 = R2
    )
  }

  # -----------------------------
  # Determine Dynamic Grouping Columns
  # -----------------------------
  group_cols <- c()

  # Guardrail: Seasonal and Yearly aggregated scale safety check
  if (any(df$month == "Dec-Feb") || any(df$month == "Mar-May") ||
          any(df$month == "Jun-Aug") || any(df$month == "Sep-Nov")) {
    if (by_month) {
      message("Cannot calculate monthly statistics on data already aggregated to 'seasonal' scale. Showing seasonal.")
    }
  }
  if (any(df$month == "1 to 12")){
    if (by_year) {
      stop("Cannot calculate separate year-by-year statistics on data already aggregated to a single yearly value per year. Showing yearly.")
    }
  }

  # Build grouping in structural hierarchy: Year -> Season -> Month -> Period
  if (by_year) {
    group_cols <- c(group_cols, "year")
  }

  if (by_season) {
    group_cols <- c(group_cols, "season")
  }

  if (by_month) {
    group_cols <- c(group_cols, "month")
  }

  if (by_period) {
    group_cols <- c(group_cols, "period")
  }

  # -----------------------------
  # Execution Path
  # -----------------------------
  if (length(group_cols) > 0) {
    sub_sets <- split(df, df[, group_cols, drop = FALSE], drop = TRUE)

    output <- lapply(sub_sets, function(sub_df) {
      temp <- .calc_stats(sub_df)
      if (is.null(temp)) return(NULL)

      for (col in group_cols) {
        temp[[col]] <- sub_df[[col]][1]
      }
      return(temp)
    })

    output <- do.call(rbind, output)

    # Sparse data safety net
    if (is.null(output) || nrow(output) == 0) {
      stop("The requested grouping combinations contain insufficient data (fewer than 2 observations per group) to calculate agreement statistics.")
    }

    stat_cols <- c("N", "ME", "MAE", "RMSE", "MaxAE", "rME",
                   "rMAE", "rRMSE", "PBIAS", "NSE", "d", "d_mod", "R2")
    output <- output[, c(group_cols, stat_cols), drop = FALSE]

    order_args <- lapply(group_cols, function(col) output[[col]])
    output <- output[do.call(order, order_args), , drop = FALSE]

    rownames(output) <- NULL

    # Safe base R rounding for numeric columns only
    num_cols <- sapply(output, is.numeric)
    output[num_cols] <- round(output[num_cols], digits = digits)

    return(output)

  } else {
    overall_out <- .calc_stats(df)
    if (!is.null(overall_out)) {
      rownames(overall_out) <- NULL
      num_cols <- sapply(overall_out, is.numeric)
      overall_out[num_cols] <- round(overall_out[num_cols], digits = digits)
    } else {
      stop("Insufficient data overall (fewer than 2 observations) to calculate agreement statistics.")
    }
    return(overall_out)
  }
}
