#' Aggregate Paired Time Series to Multiple Temporal Scales
#'
#' Aggregates paired time series (reference vs. estimate) to multiple temporal
#' scales commonly used in climatology, hydrology, and environmental sciences.
#'
#' Supported temporal scales include:
#' \itemize{
#'   \item daily (no aggregation)
#'   \item pentad (5-day periods)
#'   \item weekly (ISO weeks)
#'   \item dekad (10-day periods)
#'   \item monthly (calendar months)
#'   \item seasonal (Austral seasons: DJF, MAM, JJA, SON)
#'   \item yearly (calendar years)
#' }
#'
#' @param df A data.frame with exactly three columns:
#' \itemize{
#'   \item \code{Date}: dates
#'   \item \code{obs}: observed values
#'   \item \code{est}: estimated values
#' }
#'
#' @param scale Temporal aggregation scale.
#' @param FUN Aggregation function.
#'
#' @return A data.frame containing
#' \itemize{
#'   \item Year
#'   \item Season
#'   \item "Season-Year"
#'   \item Month
#'   \item Period
#'   \item obs
#'   \item est
#' }
#'
#' @examples
#' df <- data.frame(
#'   Date = seq(as.Date("2000-01-01"), by = "day", length.out = 9496),
#'   obs = rnorm(9496, mean = 20, sd = 3),
#'   est = rnorm(9496, mean = 20, sd = 3)
#' )
#' aggregate_scale(df, scale = "daily", FUN = mean)
#' aggregate_scale(df, scale = "dekad", FUN = mean)
#' aggregate_scale(df, scale = "weekly", FUN = mean)
#' aggregate_scale(df, scale = "monthly", FUN = mean)
#'
#' @importFrom dplyr group_by summarise across all_of case_when
#' @importFrom lubridate year isoweek yday day month parse_date_time leap_year
#' @importFrom stats na.omit median
#' @export

aggregate_scale <- function(df,
                            scale = c("daily",
                                      "pentad",
                                      "weekly",
                                      "dekad",
                                      "monthly",
                                      "seasonal",
                                      "yearly"),
                            FUN = mean) {

  scale <- match.arg(scale)

  ##------------------------------------------------------------
  ## Validation
  ##------------------------------------------------------------

  if (!is.data.frame(df) || ncol(df) != 3)
    stop("'df' must be a data.frame with three columns: 1st 'Date', 2nd observed or reference data and 3rd estimated values.")

  colnames(df) <- c("date", "obs", "est")
  if (!is.numeric(df$obs)) stop("'obs' must be numeric.")
  if (!is.numeric(df$est)) stop("'est' must be numeric.")
  if (!is.function(FUN)) stop("'FUN' must be a function.")

  ##------------------------------------------------------------
  ## Dates
  ##------------------------------------------------------------

  df$date <- .check_date(df$date)
  df <- stats::na.omit(df)
  if (nrow(df) == 0)
    stop("No complete observation-estimate pairs found after removing NA values.")

  ##------------------------------------------------------------
  ## Time components (Calculated once for base data)
  ##------------------------------------------------------------

  df$Year  <- lubridate::year(df$date)
  df$Month <- lubridate::month(df$date)

  df$Season <- dplyr::case_when(
    df$Month %in% c(12, 1, 2) ~ "Summer",
    df$Month %in% c(3, 4, 5)  ~ "Autumn",
    df$Month %in% c(6, 7, 8)  ~ "Winter",
    TRUE                      ~ "Spring"
  )

  df$SeasonYear <- df$Year
  df$SeasonYear[df$Month == 12] <- df$SeasonYear[df$Month == 12] + 1

  is_leap <- lubridate::leap_year(df$date)
  raw_doy <- lubridate::yday(df$date)
  std_doy <- ifelse(!is_leap & raw_doy >= 60, raw_doy + 1, raw_doy)

  ##------------------------------------------------------------
  ## Scale-specific Setup
  ##------------------------------------------------------------

  if (scale == "daily") {
    df$Period <- std_doy
    groups <- c("Year", "Period")

  } else if (scale == "weekly") {
    df$Period <- lubridate::isoweek(df$date)
    groups <- c("Year", "Period")

  } else if (scale == "pentad") {
    df$Period <- pmin(((std_doy - 1) %/% 5) + 1, 73)
    groups <- c("Year", "Period")

  } else if (scale == "dekad") {
    dom <- lubridate::day(df$date)
    df$Period <- dplyr::case_when(
      dom <= 10 ~ (df$Month - 1) * 3 + 1,
      dom <= 20 ~ (df$Month - 1) * 3 + 2,
      TRUE      ~ (df$Month - 1) * 3 + 3
    )
    groups <- c("Year", "Month", "Period")

  } else if (scale == "monthly") {
    df$Period <- df$Month
    groups <- c("Year", "Month", "Period")

  } else if (scale == "seasonal") {
    df$Period <- dplyr::case_when(
      df$Season == "Summer" ~ 1L,
      df$Season == "Autumn" ~ 2L,
      df$Season == "Winter" ~ 3L,
      TRUE                  ~ 4L
    )
    groups <- c("SeasonYear", "Season", "Period")

  } else if (scale == "yearly") {
    df$Period <- as.integer(factor(df$Year))
    groups <- c("Year", "Period")
  }

  ##------------------------------------------------------------
  ## Aggregation
  ##------------------------------------------------------------

  output <- df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::summarise(
      .mid_date = stats::median(date),
      obs = FUN(obs),
      est = FUN(est),
      .groups = "drop"
    )

  ##------------------------------------------------------------
  ## Post-processing: Ensure Uniform Columns
  ##------------------------------------------------------------

  # Extract components from the median date of the aggregated period
  output$Year_mid <- lubridate::year(output$.mid_date)
  output$Month_mid <- lubridate::month(output$.mid_date)

  if (scale %in% c("daily", "pentad", "weekly", "dekad", "monthly")) {

    output$Year <- output$Year_mid
    output$Month <- as.character(output$Month_mid)

    output$Season <- dplyr::case_when(
      output$Month_mid %in% c(12, 1, 2) ~ "Summer",
      output$Month_mid %in% c(3, 4, 5)  ~ "Autumn",
      output$Month_mid %in% c(6, 7, 8)  ~ "Winter",
      TRUE                              ~ "Spring"
    )

    output$`Season-Year` <- output$Year
    output$`Season-Year`[output$Month_mid == 12] <- output$`Season-Year`[output$Month_mid == 12] + 1

  } else if (scale == "seasonal") {

    output$Year <- output$Year_mid
    output$Month <- c("Summer" = "Dec-Feb",
                      "Autumn" = "Mar-May",
                      "Winter" = "Jun-Aug",
                      "Spring" = "Sep-Nov")[output$Season]

    output$`Season-Year` <- output$SeasonYear # Comes directly from 'groups'

  } else if (scale == "yearly") {

    output$Season <- 1
    output$`Season-Year` <- output$Year
    output$Month <- "1-12"
    output$Period <- 1

  }

  # Ensure the output is a standard data.frame and rigidly select/order the requested columns
  final_cols <- c("Year", "Season", "Season-Year", "Month", "Period", "obs", "est")
  output <- as.data.frame(output)[, final_cols]

  return(output)
}

#' Check User Input Dates for Validity
#' @param x User entered date value
#' @return Validated date string as a `Date` object.
#' @note This was taken from \CRANpkg{nasapower}, but tz changed to UTC.
#' @example .check_date(x)
#' @author Adam H. Sparks \email{adamhsparks@@gmail.com}
#' @keywords Internal
#' @noRd
.check_date <- function(x) {
  tryCatch(
    x <- lubridate::parse_date_time(x,
                                    c("Ymd", "dmY", "mdY", "BdY", "Bdy", "bdY", "bdy"),
                                    tz = "UTC"),

    warning = function(cond) {
      stop("One or more dates are not in a valid format. Please ensure all dates are valid.",
           call. = FALSE
      )
    }
  )
  return(as.Date(x))
}
