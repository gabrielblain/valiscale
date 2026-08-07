
<!-- README.md is generated from README.Rmd. Please edit that file -->

# valiscale

<!-- badges: start -->

<!-- badges: end -->

The goal of valiscale is to calculate several metrics for quantitative
characterization of estimation models performance.

## Installation

You can install the development version of valiscale from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("gabrielblain/valiscale")
```

## Example 1

Got paired daily data (like observed vs. estimated values) and need to
aggregate it into common environmental time scales? Here is how to
compute averages across daily, 5-day (pentad), and seasonal windows:

``` r
library(valiscale)
df <- data.frame(
Date = seq(as.Date("2000-01-01"), by = "day", length.out = 9496),
obs = rnorm(9496, mean = 20, sd = 3),
est = rnorm(9496, mean = 20, sd = 3)
)
#Keeping daily:
daily_data <- aggregate_scale(df, scale = "daily", FUN = mean)
head(daily_data)
#>   Year Season Season-Year Month Period      obs      est
#> 1 2000 Summer        2000     1      1 17.65501 22.68339
#> 2 2000 Summer        2000     1      2 22.56695 24.19298
#> 3 2000 Summer        2000     1      3 22.75520 23.58233
#> 4 2000 Summer        2000     1      4 24.88249 16.28938
#> 5 2000 Summer        2000     1      5 17.94912 18.51083
#> 6 2000 Summer        2000     1      6 19.52906 14.04427
#pentad (5-day periods):
pentad_means <- aggregate_scale(df, scale = "pentad", FUN = mean)
head(pentad_means)
#>   Year Season Season-Year Month Period      obs      est
#> 1 2000 Summer        2000     1      1 21.16175 21.05178
#> 2 2000 Summer        2000     1      2 22.64266 17.27342
#> 3 2000 Summer        2000     1      3 18.22104 20.62684
#> 4 2000 Summer        2000     1      4 16.73678 19.25993
#> 5 2000 Summer        2000     1      5 19.80955 18.99412
#> 6 2000 Summer        2000     1      6 19.78753 19.86983
#seasonal (Austral seasons: DJF, MAM, JJA, SON):
seasonal_means <- aggregate_scale(df, scale = "seasonal", FUN = mean)
head(seasonal_means)
#>   Year Season Season-Year   Month Period      obs      est
#> 1 2000 Autumn        2000 Mar-May      2 19.94459 19.72396
#> 2 2000 Spring        2000 Sep-Nov      4 19.82428 20.00259
#> 3 2000 Summer        2000 Dec-Feb      1 19.90157 19.68401
#> 4 2000 Winter        2000 Jun-Aug      3 20.21666 20.05037
#> 5 2001 Autumn        2001 Mar-May      2 20.30247 20.02992
#> 6 2001 Spring        2001 Sep-Nov      4 19.99331 19.79582
```

Note that averaging at the daily scale produces the same values as the
input data.

## Example 2

If you need totals instead of averages, swap `FUN = mean` for
`FUN = sum`:

``` r
df <- data.frame(
Date = seq(as.Date("2000-01-01"), by = "day", length.out = 9496),
obs = rnorm(9496, mean = 20, sd = 3),
est = rnorm(9496, mean = 20, sd = 3)
)
#Keeping daily:
daily_data <- aggregate_scale(df, scale = "daily", FUN = sum)
head(daily_data)
#>   Year Season Season-Year Month Period      obs      est
#> 1 2000 Summer        2000     1      1 19.24111 18.30041
#> 2 2000 Summer        2000     1      2 18.12287 17.16647
#> 3 2000 Summer        2000     1      3 19.21192 18.12543
#> 4 2000 Summer        2000     1      4 25.50812 13.48931
#> 5 2000 Summer        2000     1      5 17.97373 16.86194
#> 6 2000 Summer        2000     1      6 22.36063 16.11481
#pentad (5-day periods):
pentad_sum <- aggregate_scale(df, scale = "pentad", FUN = sum)
head(pentad_sum)
#>   Year Season Season-Year Month Period       obs       est
#> 1 2000 Summer        2000     1      1 100.05776  83.94356
#> 2 2000 Summer        2000     1      2 111.90509  90.56253
#> 3 2000 Summer        2000     1      3  90.01128  94.46198
#> 4 2000 Summer        2000     1      4  95.95554  96.73350
#> 5 2000 Summer        2000     1      5 107.80442  98.44125
#> 6 2000 Summer        2000     1      6  94.93461 101.24487
#seasonal (Austral seasons: DJF, MAM, JJA, SON):
seasonal_sum <- aggregate_scale(df, scale = "seasonal", FUN = sum)
head(seasonal_sum)
#>   Year Season Season-Year   Month Period      obs      est
#> 1 2000 Autumn        2000 Mar-May      2 1866.142 1779.605
#> 2 2000 Spring        2000 Sep-Nov      4 1779.317 1823.157
#> 3 2000 Summer        2000 Dec-Feb      1 1208.506 1171.746
#> 4 2000 Winter        2000 Jun-Aug      3 1872.989 1810.600
#> 5 2001 Autumn        2001 Mar-May      2 1826.473 1792.277
#> 6 2001 Spring        2001 Sep-Nov      4 1826.058 1804.277
```

Note that summing at the daily scale produces the same values as the
input data.

## Example 3

Now let’s evaluate model performance across different time scales using
the aggregated data from Example 1:

``` r
#Performance for daily values:
agreement_stats(df=daily_data)
#>      N    ME  MAE RMSE MaxAE   rME  rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1 9496 -0.02 3.38 4.25 16.06 -0.11 16.88 21.22 -0.11 -0.97 0.39   0.3  0
#Performance for pentad values:
agreement_stats(df=pentad_means)
#>      N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1 1898 -0.06 1.52 1.91  6.37 -0.28 7.62  9.54 -0.28 -1.09 0.38  0.29  0
#Performance for seasonal values (Austral seasons: DJF, MAM, JJA, SON):
agreement_stats(df=seasonal_means)
#>     N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE   d d_mod   R2
#> 1 105 -0.06 0.37 0.48  1.22 -0.28 1.87  2.39 -0.28 -1.36 0.3  0.25 0.03
```

## Example 4

Overall stats are great, but let’s see if model performance varies
across different seasons:

``` r
#Seasonal performance for daily values in the:
agreement_stats(df=daily_data, by_season = TRUE)
#>   season    N    ME  MAE RMSE MaxAE   rME  rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1 Autumn 2392 -0.06 3.31 4.17 14.61 -0.31 16.51 20.83 -0.31 -0.94 0.40  0.30  0
#> 2 Spring 2366  0.05 3.38 4.22 14.48  0.26 16.94 21.18  0.26 -0.93 0.40  0.30  0
#> 3 Summer 2346  0.00 3.47 4.36 16.06  0.00 17.28 21.75  0.00 -1.04 0.37  0.28  0
#> 4 Winter 2392 -0.07 3.37 4.24 15.73 -0.37 16.80 21.12 -0.37 -0.98 0.39  0.29  0
#Seasonal performance for pentad values:
agreement_stats(df=pentad_means, by_season = TRUE)
#>   season   N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 Autumn 468 -0.07 1.66 2.07  6.37 -0.33 8.33 10.36 -0.33 -1.01 0.35  0.27 0.01
#> 2 Spring 468 -0.07 1.42 1.79  5.54 -0.34 7.12  8.99 -0.34 -1.15 0.42  0.32 0.00
#> 3 Summer 468 -0.06 1.45 1.81  6.03 -0.29 7.24  9.03 -0.29 -0.93 0.41  0.30 0.00
#> 4 Winter 494 -0.03 1.56 1.94  5.84 -0.17 7.78  9.71 -0.17 -1.30 0.35  0.27 0.00
#Seasonal performance for seasonal values (Austral seasons: DJF, MAM, JJA, SON):
agreement_stats(df=seasonal_means, by_season = TRUE)
#>   season  N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 Autumn 26 -0.08 0.34 0.42  0.93 -0.38 1.72  2.10 -0.38 -0.71 0.37  0.27 0.00
#> 2 Spring 26 -0.06 0.42 0.54  1.22 -0.32 2.09  2.72 -0.32 -4.01 0.12  0.13 0.30
#> 3 Summer 27 -0.06 0.32 0.43  1.11 -0.29 1.61  2.13 -0.29 -0.62 0.46  0.36 0.00
#> 4 Winter 26 -0.03 0.41 0.51  0.99 -0.13 2.05  2.56 -0.13 -1.49 0.23  0.23 0.11
```

## Example 5

Great. Let’s see if model performance varies across different months:

``` r
# Monthly performance for daily values
agreement_stats(df = daily_data, by_month = TRUE)
#>    month   N    ME  MAE RMSE MaxAE   rME  rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1      1 806  0.12 3.43 4.30 14.51  0.60 17.23 21.57  0.60 -1.03 0.37  0.28  0
#> 2     10 806  0.21 3.40 4.20 12.35  1.04 17.19 21.25  1.04 -0.85 0.41  0.30  0
#> 3     11 780 -0.21 3.44 4.29 14.48 -1.05 17.15 21.38 -1.05 -0.88 0.42  0.31  0
#> 4     12 805  0.15 3.49 4.40 13.04  0.76 17.47 22.03  0.76 -1.03 0.36  0.29  0
#> 5      2 735 -0.30 3.47 4.39 16.06 -1.49 17.14 21.65 -1.49 -1.08 0.37  0.29  0
#> 6      3 806 -0.12 3.36 4.26 14.11 -0.60 16.73 21.17 -0.60 -1.06 0.39  0.29  0
#> 7      4 780 -0.23 3.35 4.20 14.61 -1.13 16.70 20.92 -1.13 -0.93 0.39  0.30  0
#> 8      5 806  0.16 3.21 4.07 13.71  0.79 16.09 20.39  0.79 -0.84 0.43  0.32  0
#> 9      6 780 -0.09 3.26 4.08 12.84 -0.46 16.26 20.31 -0.46 -0.74 0.42  0.31  0
#> 10     7 806  0.04 3.37 4.25 13.17  0.20 16.77 21.17  0.20 -1.04 0.39  0.30  0
#> 11     8 806 -0.17 3.47 4.37 15.73 -0.86 17.35 21.84 -0.86 -1.16 0.36  0.28  0
#> 12     9 780  0.16 3.29 4.18 14.20  0.78 16.47 20.90  0.78 -1.11 0.38  0.29  0
# Monthly performance for pentad values (5-day averages)
agreement_stats(df = pentad_means, by_month = TRUE)
#>    month   N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1      1 156  0.20 1.62 2.01  6.03  1.01 8.13 10.13  1.01 -1.11 0.34  0.26 0.01
#> 2     10 156 -0.04 1.44 1.83  5.17 -0.22 7.20  9.16 -0.22 -1.10 0.37  0.28 0.00
#> 3     11 156  0.06 1.44 1.84  5.54  0.31 7.28  9.27  0.31 -1.48 0.42  0.32 0.00
#> 4     12 156 -0.21 1.37 1.75  4.79 -1.04 6.80  8.66 -1.04 -1.02 0.44  0.33 0.01
#> 5      2 156 -0.17 1.37 1.66  5.10 -0.82 6.80  8.23 -0.82 -0.71 0.46  0.32 0.02
#> 6      3 156 -0.14 1.54 1.90  4.92 -0.71 7.70  9.49 -0.71 -0.78 0.43  0.30 0.00
#> 7      4 156 -0.15 1.71 2.14  6.37 -0.74 8.47 10.64 -0.74 -1.12 0.34  0.27 0.02
#> 8      5 156  0.10 1.75 2.16  5.83  0.48 8.81 10.89  0.48 -1.18 0.29  0.22 0.02
#> 9      6 156  0.01 1.64 2.04  4.86  0.05 8.25 10.27  0.05 -1.22 0.29  0.24 0.02
#> 10     7 182  0.02 1.56 1.93  5.84  0.12 7.78  9.64  0.12 -1.52 0.37  0.27 0.00
#> 11     8 156 -0.15 1.47 1.85  5.67 -0.73 7.32  9.22 -0.73 -1.16 0.38  0.30 0.00
#> 12     9 156 -0.22 1.38 1.72  5.48 -1.10 6.89  8.53 -1.10 -0.96 0.48  0.34 0.02
# Monthly performance for seasonal values
# Note: Since seasonal values are already aggregated into 3-month blocks,
# attempting to compute monthly stats here will (correctly) throw an error/warning.
agreement_stats(df = seasonal_means, by_month = TRUE)
#> Cannot calculate monthly statistics on data already aggregated to 'seasonal' scale. Showing seasonal.
#>     month  N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 Dec-Feb 27 -0.06 0.32 0.43  1.11 -0.29 1.61  2.13 -0.29 -0.62 0.46  0.36 0.00
#> 2 Jun-Aug 26 -0.03 0.41 0.51  0.99 -0.13 2.05  2.56 -0.13 -1.49 0.23  0.23 0.11
#> 3 Mar-May 26 -0.08 0.34 0.42  0.93 -0.38 1.72  2.10 -0.38 -0.71 0.37  0.27 0.00
#> 4 Sep-Nov 26 -0.06 0.42 0.54  1.22 -0.32 2.09  2.72 -0.32 -4.01 0.12  0.13 0.30
```
