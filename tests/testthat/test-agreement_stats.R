# ============================================================
# Tests for agreement_stats()
# ============================================================


# ------------------------------------------------------------
# Helper data
# ------------------------------------------------------------

test_data <- data.frame(
  year = c(2000, 2000, 2000, 2000, 2001, 2001, 2001, 2001),
  season = c(
    "Summer", "Summer", "Autumn", "Autumn",
    "Summer", "Summer", "Autumn", "Autumn"
  ),
  seasonyear = c(
    2000, 2000, 2000, 2000,
    2001, 2001, 2001, 2001
  ),
  month = c("1", "1", "3", "3", "1", "1", "3", "3"),
  period = c(1, 2, 7, 8, 1, 2, 7, 8),
  obs = c(1, 2, 3, 4, 2, 4, 6, 8),
  est = c(2, 3, 2, 5, 1, 5, 7, 7)
)


# ------------------------------------------------------------
# Basic validation
# ------------------------------------------------------------

test_that("agreement_stats validates the input data frame", {

  expect_error(
    agreement_stats(1:10),
    "'df' must be a data.frame"
  )

  df_bad <- test_data[, 1:6]

  expect_error(
    agreement_stats(df_bad),
    "exactly seven columns"
  )

  df_bad <- test_data
  names(df_bad)[7] <- "prediction"

  expect_error(
    agreement_stats(df_bad),
    "exactly seven columns"
  )
})


test_that("agreement_stats accepts upper-case input column names", {

  df <- test_data
  names(df) <- toupper(names(df))

  result <- agreement_stats(df)

  expect_s3_class(result, "data.frame")
  expect_equal(result$N, 8)
})


test_that("agreement_stats validates the grouping argument", {

  expect_error(
    agreement_stats(test_data, by = "invalid"),
    "should be one of"
  )

  expect_error(
    agreement_stats(test_data, by = c("year", "month")),
    "must be of length 1"
  )
})


test_that("agreement_stats validates digits", {

  expect_error(
    agreement_stats(test_data, digits = "2"),
    "'digits' must be a single non-negative integer"
  )

  expect_error(
    agreement_stats(test_data, digits = -1),
    "'digits' must be a single non-negative integer"
  )

  expect_error(
    agreement_stats(test_data, digits = 2.5),
    "'digits' must be a single non-negative integer"
  )

  expect_error(
    agreement_stats(test_data, digits = c(2, 3)),
    "'digits' must be a single non-negative integer"
  )

  expect_error(
    agreement_stats(test_data, digits = NA),
    "'digits' must be a single non-negative integer"
  )

  expect_no_error(
    agreement_stats(test_data, digits = 0)
  )
})


# ------------------------------------------------------------
# Output structure
# ------------------------------------------------------------

test_that("agreement_stats returns the expected overall columns", {

  result <- agreement_stats(test_data)

  expected <- c(
    "N",
    "ME",
    "MAE",
    "MSE",
    "RMSE",
    "MaxAE",
    "rME",
    "rMAE",
    "rMSE",
    "rRMSE",
    "PBIAS",
    "NSE",
    "d",
    "d_mod",
    "R",
    "R2",
    "MAEb",
    "MAEp",
    "MAEu",
    "MAEs",
    "KGE",
    "alfa",
    "beta"
  )

  expect_named(result, expected)
  expect_equal(nrow(result), 1)
})


# ------------------------------------------------------------
# Basic error statistics
# ------------------------------------------------------------

test_that("agreement_stats calculates basic error statistics correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  obs <- df$obs
  est <- df$est
  err <- est - obs

  expect_equal(result$N, 4)
  expect_equal(result$ME, mean(err))
  expect_equal(result$MAE, mean(abs(err)))
  expect_equal(result$MSE, mean(err^2))
  expect_equal(result$RMSE, sqrt(mean(err^2)))
  expect_equal(result$MaxAE, max(abs(err)))
})


# ------------------------------------------------------------
# Relative statistics and PBIAS
# ------------------------------------------------------------

test_that("agreement_stats calculates relative statistics correctly", {

  df <- data.frame(
    year = rep(2000, 4),
    season = rep("Summer", 4),
    seasonyear = rep(2000, 4),
    month = rep("1", 4),
    period = 1:4,
    obs = c(1, 2, 3, 4),
    est = c(2, 3, 4, 5)
  )

  result <- agreement_stats(df, digits = 10)

  obs <- df$obs
  est <- df$est

  ME <- mean(est - obs)
  MAE <- mean(abs(est - obs))
  MSE <- mean((est - obs)^2)
  RMSE <- sqrt(MSE)
  mean_obs <- mean(obs)

  expect_equal(
    result$rME,
    100 * ME / mean_obs
  )

  expect_equal(
    result$rMAE,
    100 * MAE / mean_obs
  )

  expect_equal(
    result$rMSE,
    100 * MSE / (mean_obs^2)
  )

  expect_equal(
    result$rRMSE,
    100 * RMSE / mean_obs
  )

  expect_equal(
    result$PBIAS,
    100 * sum(est - obs) / sum(obs)
  )
})


test_that("agreement_stats returns NA for relative statistics when mean obs is zero", {

  df <- data.frame(
    year = rep(2000, 2),
    season = rep("Summer", 2),
    seasonyear = rep(2000, 2),
    month = rep("1", 2),
    period = 1:2,
    obs = c(-1, 1),
    est = c(0, 2)
  )

  result <- agreement_stats(df)

  expect_true(is.na(result$rME))
  expect_true(is.na(result$rMAE))
  expect_true(is.na(result$rMSE))
  expect_true(is.na(result$rRMSE))
})


test_that("agreement_stats returns NA for PBIAS when sum obs is zero", {

  df <- data.frame(
    year = rep(2000, 2),
    season = rep("Summer", 2),
    seasonyear = rep(2000, 2),
    month = rep("1", 2),
    period = 1:2,
    obs = c(-1, 1),
    est = c(0, 2)
  )

  result <- agreement_stats(df)

  expect_true(is.na(result$PBIAS))
})


# ------------------------------------------------------------
# NSE
# ------------------------------------------------------------

test_that("agreement_stats calculates NSE correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  obs <- df$obs
  est <- df$est

  expected_nse <-
    1 - sum((obs - est)^2) /
    sum((obs - mean(obs))^2)

  expect_equal(
    result$NSE,
    expected_nse
  )
})


test_that("agreement_stats returns NA for NSE with constant observations", {
  df <- test_data[1:4, ]
  df$obs <- 5
  expect_warning(
    result <- agreement_stats(df),
    "standard deviation is zero"
  )
  expect_true(is.na(result$NSE))
})


# ------------------------------------------------------------
# Willmott indices
# ------------------------------------------------------------

test_that("agreement_stats calculates Willmott d correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  obs <- df$obs
  est <- df$est
  mean_obs <- mean(obs)

  den_d <- sum(
    (abs(est - mean_obs) +
       abs(obs - mean_obs))^2
  )

  expected_d <-
    1 - sum((obs - est)^2) / den_d

  expect_equal(
    result$d,
    expected_d
  )
})


test_that("agreement_stats calculates modified Willmott d correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  obs <- df$obs
  est <- df$est
  mean_obs <- mean(obs)

  den_dm <- sum(
    abs(est - mean_obs) +
      abs(obs - mean_obs)
  )

  expected_d_mod <-
    1 - sum(abs(obs - est)) / den_dm

  expect_equal(
    result$d_mod,
    expected_d_mod
  )
})


# ------------------------------------------------------------
# Correlation
# ------------------------------------------------------------

test_that("agreement_stats calculates R and R2 correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  expected_R <- cor(df$obs, df$est)

  expect_equal(
    result$R,
    expected_R
  )

  expect_equal(
    result$R2,
    expected_R^2
  )
})


# ------------------------------------------------------------
# KGE
# ------------------------------------------------------------

test_that("agreement_stats calculates KGE components correctly", {

  df <- test_data[1:4, ]

  result <- agreement_stats(df, digits = 10)

  R <- cor(df$obs, df$est)
  alfa <- sd(df$est) / sd(df$obs)
  beta <- mean(df$est) / mean(df$obs)

  ED <- sqrt(
    (R - 1)^2 +
      (alfa - 1)^2 +
      (beta - 1)^2
  )

  expected_KGE <- 1 - ED

  expect_equal(result$alfa, alfa)
  expect_equal(result$beta, beta)
  expect_equal(result$KGE, expected_KGE)
})


# ------------------------------------------------------------
# Robeson & Willmott MAE decomposition
# ------------------------------------------------------------

test_that("agreement_stats returns all MAE decomposition components", {

  result <- agreement_stats(test_data)

  expect_true("MAEb" %in% names(result))
  expect_true("MAEp" %in% names(result))
  expect_true("MAEu" %in% names(result))
  expect_true("MAEs" %in% names(result))

  expect_true(is.numeric(result$MAEb))
  expect_true(is.numeric(result$MAEp))
  expect_true(is.numeric(result$MAEu))
  expect_true(is.numeric(result$MAEs))
})


test_that("agreement_stats MAE decomposition conserves total MAE", {

  result <- agreement_stats(
    test_data,
    digits = 10
  )

  expect_equal(
    result$MAEb +
      result$MAEp +
      result$MAEu,
    result$MAE,
    tolerance = 1e-10
  )

  expect_equal(
    result$MAEs,
    result$MAEb + result$MAEp,
    tolerance = 1e-10
  )
})


test_that("agreement_stats gives zero MAE components for perfect agreement", {

  df <- test_data
  df$est <- df$obs

  result <- agreement_stats(
    df,
    digits = 10
  )

  expect_equal(result$MAE, 0)
  expect_equal(result$MAEb, 0)
  expect_equal(result$MAEp, 0)
  expect_equal(result$MAEu, 0)
  expect_equal(result$MAEs, 0)
})


# ------------------------------------------------------------
# Missing values
# ------------------------------------------------------------

test_that("agreement_stats removes incomplete obs-est pairs", {

  df <- test_data[1:4, ]

  df$obs[2] <- NA
  df$est[3] <- NA

  result <- agreement_stats(df)

  expect_equal(result$N, 2)
})


# ------------------------------------------------------------
# Overall versus grouped statistics
# ------------------------------------------------------------

test_that("agreement_stats calculates statistics overall when by is NULL", {

  result <- agreement_stats(test_data)

  expect_equal(nrow(result), 1)
  expect_equal(result$N, nrow(test_data))
})


test_that("agreement_stats calculates statistics by year", {

  result <- agreement_stats(
    test_data,
    by = "year"
  )

  expect_equal(nrow(result), 2)

  expect_equal(
    result$year,
    c(2000, 2001)
  )

  expect_equal(
    result$N,
    c(4, 4)
  )
})


test_that("agreement_stats calculates statistics by season", {

  result <- agreement_stats(
    test_data,
    by = "season"
  )

  expect_equal(nrow(result), 2)

  expect_equal(
    result$season,
    c("Autumn", "Summer")
  )

  expect_equal(
    result$N,
    c(4, 4)
  )
})


test_that("agreement_stats calculates statistics by month", {

  result <- agreement_stats(
    test_data,
    by = "month"
  )

  expect_equal(nrow(result), 2)

  expect_equal(
    result$month,
    c("1", "3")
  )

  expect_equal(
    result$N,
    c(4, 4)
  )
})


test_that("agreement_stats calculates statistics by period", {

  result <- agreement_stats(
    test_data,
    by = "period"
  )

  expect_equal(nrow(result), 4)

  expect_equal(
    result$period,
    c(1, 2, 7, 8)
  )

  expect_equal(
    result$N,
    c(2, 2, 2, 2)
  )
})


# ------------------------------------------------------------
# Grouped statistics should agree with independent calculations
# ------------------------------------------------------------

test_that("agreement_stats grouped results agree with independent calculations", {

  df_2000 <- test_data[test_data$year == 2000, ]

  grouped <- agreement_stats(
    test_data,
    by = "year",
    digits = 10
  )

  independent <- agreement_stats(
    df_2000,
    digits = 10
  )

  row_2000 <- grouped[grouped$year == 2000, ]

  expect_equal(
    row_2000$N,
    independent$N
  )

  expect_equal(
    row_2000$ME,
    independent$ME
  )

  expect_equal(
    row_2000$MAE,
    independent$MAE
  )

  expect_equal(
    row_2000$RMSE,
    independent$RMSE
  )

  expect_equal(
    row_2000$NSE,
    independent$NSE
  )
})


# ------------------------------------------------------------
# Rounding
# ------------------------------------------------------------

test_that("agreement_stats rounds numeric statistics according to digits", {

  result <- agreement_stats(
    test_data,
    digits = 0
  )

  numeric_columns <- vapply(
    result,
    is.numeric,
    logical(1)
  )

  for (x in result[numeric_columns]) {
    expect_equal(
      x,
      round(x, 0)
    )
  }
})


test_that("agreement_stats preserves full precision when digits is sufficiently large", {

  result <- agreement_stats(
    test_data,
    digits = 10
  )

  expected_ME <- mean(test_data$est - test_data$obs)

  expect_equal(
    result$ME,
    expected_ME
  )
})


# ------------------------------------------------------------
# Sparse groups
# ------------------------------------------------------------

test_that("agreement_stats rejects groups with fewer than two observations", {

  df <- data.frame(
    year = c(2000, 2001),
    season = c("Summer", "Summer"),
    seasonyear = c(2000, 2001),
    month = c("1", "1"),
    period = c(1, 1),
    obs = c(1, 2),
    est = c(2, 3)
  )

  expect_error(
    agreement_stats(df, by = "year"),
    "insufficient data"
  )
})


test_that("agreement_stats rejects overall data with fewer than two observations", {

  df <- test_data[1, ]

  expect_error(
    agreement_stats(df),
    "Insufficient data overall"
  )
})


# ------------------------------------------------------------
# Seasonal-scale safety check
# ------------------------------------------------------------

test_that("agreement_stats rejects monthly grouping for seasonal-scale data", {

  df <- test_data
  df$month <- rep("Dec-Feb", nrow(df))

  expect_error(
    agreement_stats(df, by = "month"),
    "already aggregated to seasonal scale"
  )
})


# ------------------------------------------------------------
# Yearly-scale safety check
# ------------------------------------------------------------

test_that("agreement_stats rejects monthly grouping for yearly-scale data", {

  df <- test_data
  df$month <- rep("1 to 12", nrow(df))

  expect_error(
    agreement_stats(df, by = "month"),
    "already aggregated to yearly scale"
  )
})
