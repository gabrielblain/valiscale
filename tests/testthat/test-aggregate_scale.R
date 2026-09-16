# ============================================================
# Tests for aggregate_scale()
# ============================================================

test_that("aggregate_scale validates input", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:9,
    obs = 1:10,
    est = 11:20
  )

  # df must have exactly three columns
  expect_error(
    aggregate_scale(df[, 1:2], scale = "daily"),
    "'df' must be a data.frame with three columns: 1st 'Date', 2nd observed or reference data and 3rd estimated values."
  )

  # obs must be numeric
  df_bad <- df
  df_bad$obs <- as.character(df_bad$obs)

  expect_error(
    aggregate_scale(df_bad, scale = "daily"),
    "'obs' must be numeric"
  )

  # est must be numeric
  df_bad <- df
  df_bad$est <- as.character(df_bad$est)

  expect_error(
    aggregate_scale(df_bad, scale = "daily"),
    "'est' must be numeric"
  )

  # FUN must be a function
  expect_error(
    aggregate_scale(df, scale = "daily", FUN = "mean"),
    "'FUN' must be a function"
  )

  # Invalid scale
  expect_error(
    aggregate_scale(df, scale = "invalid"),
    "should be one of"
  )
})


test_that("aggregate_scale handles missing values", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:4,
    obs = c(1, 2, NA, 4, 5),
    est = c(1, NA, 3, 4, 5)
  )

  result <- aggregate_scale(df, scale = "daily", FUN = mean)

  # Only complete pairs should remain
  expect_equal(nrow(result), 3)

  expect_false(anyNA(result$obs))
  expect_false(anyNA(result$est))
})


test_that("aggregate_scale rejects data with no complete pairs", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:2,
    obs = c(NA, NA, NA),
    est = c(NA, NA, NA)
  )

  expect_error(
    aggregate_scale(df, scale = "daily"),
    "'obs' must be numeric."
  )
})


test_that("aggregate_scale returns the expected columns", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:9,
    obs = 1:10,
    est = 11:20
  )

  result <- aggregate_scale(df, scale = "daily")

  expect_named(
    result,
    c("Year", "Season", "SeasonYear", "Month",
      "Period", "obs", "est")
  )

  expect_s3_class(result, "data.frame")
})


# ------------------------------------------------------------
# Daily
# ------------------------------------------------------------

test_that("aggregate_scale daily preserves daily observations", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:9,
    obs = 1:10,
    est = 11:20
  )

  result <- aggregate_scale(df, scale = "daily", FUN = mean)

  expect_equal(nrow(result), 10)

  expect_equal(result$Year, rep(2000, 10))
  expect_equal(result$Period, 1:10)

  expect_equal(result$obs, 1:10)
  expect_equal(result$est, 11:20)

  expect_equal(
    result$Season,
    rep("Summer", 10)
  )

  expect_equal(
    result$SeasonYear,
    rep(2000, 10)
  )
})


# ------------------------------------------------------------
# Monthly
# ------------------------------------------------------------

test_that("aggregate_scale monthly aggregates calendar months", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-01-01",
      "2000-01-15",
      "2000-02-01",
      "2000-02-15",
      "2000-03-01",
      "2000-03-15"
    )),
    obs = c(1, 3, 5, 7, 9, 11),
    est = c(2, 4, 6, 8, 10, 12)
  )

  result <- aggregate_scale(df, scale = "monthly", FUN = mean)

  expect_equal(nrow(result), 3)

  expect_equal(result$Year, rep(2000, 3))
  expect_equal(result$Month, c("1", "2", "3"))

  expect_equal(result$obs, c(2, 6, 10))
  expect_equal(result$est, c(3, 7, 11))

  expect_equal(
    result$Season,
    c("Summer", "Summer", "Autumn")
  )

  expect_equal(
    result$SeasonYear,
    c(2000, 2000, 2000)
  )
})


# ------------------------------------------------------------
# Dekad
# ------------------------------------------------------------

test_that("aggregate_scale dekad creates three periods per month", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-01-01", "2000-01-10",
      "2000-01-11", "2000-01-20",
      "2000-01-21", "2000-01-31"
    )),
    obs = c(1, 3, 5, 7, 9, 11),
    est = c(2, 4, 6, 8, 10, 12)
  )

  result <- aggregate_scale(df, scale = "dekad", FUN = mean)

  expect_equal(nrow(result), 3)

  expect_equal(result$Year, rep(2000, 3))
  expect_equal(result$Month, rep("1", 3))
  expect_equal(result$Period, 1:3)

  expect_equal(result$obs, c(2, 6, 10))
  expect_equal(result$est, c(3, 7, 11))

  expect_equal(
    result$Season,
    rep("Summer", 3)
  )

  expect_equal(
    result$SeasonYear,
    rep(2000, 3)
  )
})


# ------------------------------------------------------------
# Weekly
# ------------------------------------------------------------

test_that("aggregate_scale weekly aggregates ISO weeks", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:20,
    obs = 1:21,
    est = 21:1
  )

  result <- aggregate_scale(df, scale = "weekly", FUN = mean)

  expect_true(nrow(result) > 1)

  expect_true(all(result$Period >= 1))
  expect_true(all(result$Period <= 53))

  expect_equal(
    result$obs[1],
    6
  )

  expect_equal(
    result$est[1],
    16.0
  )
})


# ------------------------------------------------------------
# Pentad
# ------------------------------------------------------------

test_that("aggregate_scale pentad creates five-day periods", {

  df <- data.frame(
    Date = as.Date("2000-01-01") + 0:9,
    obs = 1:10,
    est = 11:20
  )

  result <- aggregate_scale(df, scale = "pentad", FUN = mean)

  expect_equal(nrow(result), 2)

  expect_equal(result$Year, c(2000, 2000))
  expect_equal(result$Period, c(1, 2))

  expect_equal(result$obs, c(3, 8))
  expect_equal(result$est, c(13, 18))
})


# ------------------------------------------------------------
# Seasonal
# ------------------------------------------------------------

test_that("aggregate_scale seasonal assigns austral seasons correctly", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-01-15",
      "2000-04-15",
      "2000-07-15",
      "2000-10-15"
    )),
    obs = c(1, 2, 3, 4),
    est = c(10, 20, 30, 40)
  )

  result <- aggregate_scale(df, scale = "seasonal", FUN = mean)

  expect_equal(nrow(result), 4)

  expect_equal(
    result$Season,
    c("Autumn", "Spring", "Summer", "Winter")
  )

  expect_equal(
    result$Month,
    c("Mar-May", "Sep-Nov", "Dec-Feb", "Jun-Aug")
  )

  expect_equal(
    result$Period,
    c(2, 4, 1, 3)
  )

  expect_equal(
    result$SeasonYear,
    c(2000, 2000, 2000, 2000)
  )
})


test_that("aggregate_scale assigns December to the following season-year", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-12-15",
      "2001-01-15",
      "2001-02-15"
    )),
    obs = c(1, 2, 3),
    est = c(10, 20, 30)
  )

  result <- aggregate_scale(df, scale = "seasonal", FUN = mean)

  expect_equal(nrow(result), 1)

  expect_equal(result$Season, "Summer")
  expect_equal(result$SeasonYear, 2001)
  expect_equal(result$Month, "Dec-Feb")

  expect_equal(result$obs, 2)
  expect_equal(result$est, 20)
})


# ------------------------------------------------------------
# Yearly
# ------------------------------------------------------------

test_that("aggregate_scale yearly aggregates complete calendar years", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-01-01",
      "2000-12-31",
      "2001-01-01",
      "2001-12-31"
    )),
    obs = c(1, 3, 5, 7),
    est = c(2, 4, 6, 8)
  )

  result <- aggregate_scale(df, scale = "yearly", FUN = mean)

  expect_equal(nrow(result), 2)

  expect_equal(result$Year, c(2000, 2001))
  expect_equal(result$Season, c(1, 1))
  expect_equal(result$SeasonYear, c(2000, 2001))
  expect_equal(result$Month, c("1-12", "1-12"))
  expect_equal(result$Period, c(1, 1))

  expect_equal(result$obs, c(2, 6))
  expect_equal(result$est, c(3, 7))
})


# ------------------------------------------------------------
# Custom aggregation function
# ------------------------------------------------------------

test_that("aggregate_scale accepts custom aggregation functions", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-01-01",
      "2000-01-02",
      "2000-01-03"
    )),
    obs = c(1, 100, 3),
    est = c(10, 200, 30)
  )

  result <- aggregate_scale(
    df,
    scale = "monthly",
    FUN = median
  )

  expect_equal(result$obs, 3)
  expect_equal(result$est, 30)
})


# ------------------------------------------------------------
# Leap year / standardized day of year
# ------------------------------------------------------------

test_that("aggregate_scale handles February 29 consistently", {

  df <- data.frame(
    Date = as.Date(c(
      "2000-02-28",
      "2000-02-29",
      "2000-03-01"
    )),
    obs = c(1, 2, 3),
    est = c(10, 20, 30)
  )

  result <- aggregate_scale(
    df,
    scale = "daily",
    FUN = mean
  )

  expect_equal(result$Period, c(59, 60, 61))
})


test_that("aggregate_scale standardizes day of year in non-leap years", {

  df <- data.frame(
    Date = as.Date(c(
      "2001-02-28",
      "2001-03-01",
      "2001-03-02"
    )),
    obs = c(1, 2, 3),
    est = c(10, 20, 30)
  )

  result <- aggregate_scale(
    df,
    scale = "daily",
    FUN = mean
  )

  # March 1 in a non-leap year is assigned standardized DOY 61
  expect_equal(
    result$Period,
    c(59, 61, 62)
  )
})


# ------------------------------------------------------------
# Date validation
# ------------------------------------------------------------

test_that("aggregate_scale accepts common date formats", {

  df <- data.frame(
    Date = c("2000-01-01", "2000-01-02"),
    obs = c(1, 2),
    est = c(3, 4)
  )

  result <- aggregate_scale(
    df,
    scale = "daily"
  )

  expect_equal(nrow(result), 2)
  expect_equal(result$Year, c(2000, 2000))
})


test_that("aggregate_scale rejects invalid dates", {

  df <- data.frame(
    Date = c("2000-01-01", "not-a-date"),
    obs = c(1, 2),
    est = c(3, 4)
  )

  expect_error(
    aggregate_scale(df, scale = "daily"),
    "dates are not in a valid format"
  )
})
