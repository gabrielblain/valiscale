
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
#> 1 2000 Summer        2000     1      1 22.56429 20.72299
#> 2 2000 Summer        2000     1      2 23.55354 20.68750
#> 3 2000 Summer        2000     1      3 19.61449 23.43996
#> 4 2000 Summer        2000     1      4 21.24970 21.16384
#> 5 2000 Summer        2000     1      5 21.94033 14.61088
#> 6 2000 Summer        2000     1      6 19.82700 21.67254
#pentad (5-day periods):
pentad_means <- aggregate_scale(df, scale = "pentad", FUN = mean)
head(pentad_means)
#>   Year Season Season-Year Month Period      obs      est
#> 1 2000 Summer        2000     1      1 21.78447 20.12503
#> 2 2000 Summer        2000     1      2 21.12008 20.69453
#> 3 2000 Summer        2000     1      3 21.46554 19.77192
#> 4 2000 Summer        2000     1      4 20.48562 18.83192
#> 5 2000 Summer        2000     1      5 17.72067 20.76008
#> 6 2000 Summer        2000     1      6 23.54023 19.17352
#seasonal (Austral seasons: DJF, MAM, JJA, SON):
seasonal_means <- aggregate_scale(df, scale = "seasonal", FUN = mean)
head(seasonal_means)
#>   Year Season Season-Year   Month Period      obs      est
#> 1 2000 Autumn        2000 Mar-May      2 20.24109 19.93160
#> 2 2000 Spring        2000 Sep-Nov      4 20.66264 20.14956
#> 3 2000 Summer        2000 Dec-Feb      1 20.64764 19.87667
#> 4 2000 Winter        2000 Jun-Aug      3 19.72267 20.11811
#> 5 2001 Autumn        2001 Mar-May      2 19.81820 19.96328
#> 6 2001 Spring        2001 Sep-Nov      4 20.11608 20.12943
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
#> 1 2000 Summer        2000     1      1 26.55188 24.63907
#> 2 2000 Summer        2000     1      2 16.20010 17.94633
#> 3 2000 Summer        2000     1      3 23.91945 21.17176
#> 4 2000 Summer        2000     1      4 17.86678 21.87847
#> 5 2000 Summer        2000     1      5 18.24496 20.74870
#> 6 2000 Summer        2000     1      6 17.07901 17.50277
#pentad (5-day periods):
pentad_sum <- aggregate_scale(df, scale = "pentad", FUN = sum)
head(pentad_sum)
#>   Year Season Season-Year Month Period       obs       est
#> 1 2000 Summer        2000     1      1 102.78317 106.38433
#> 2 2000 Summer        2000     1      2  96.46653  99.84806
#> 3 2000 Summer        2000     1      3 106.58267  85.15223
#> 4 2000 Summer        2000     1      4 106.06079  99.03422
#> 5 2000 Summer        2000     1      5  98.03315 104.26056
#> 6 2000 Summer        2000     1      6 105.66066 103.67662
#seasonal (Austral seasons: DJF, MAM, JJA, SON):
seasonal_sum <- aggregate_scale(df, scale = "seasonal", FUN = sum)
head(seasonal_sum)
#>   Year Season Season-Year   Month Period      obs      est
#> 1 2000 Autumn        2000 Mar-May      2 1815.611 1875.067
#> 2 2000 Spring        2000 Sep-Nov      4 1797.060 1836.838
#> 3 2000 Summer        2000 Dec-Feb      1 1212.911 1187.918
#> 4 2000 Winter        2000 Jun-Aug      3 1862.025 1831.309
#> 5 2001 Autumn        2001 Mar-May      2 1805.430 1860.837
#> 6 2001 Spring        2001 Sep-Nov      4 1846.091 1818.628
```

Note that summing at the daily scale produces the same values as the
input data.

## Example 3

Now let’s evaluate model performance across different time scales using
the aggregated data from Example 1:

``` r
#Performance for daily values:
agreement_stats(df=daily_data)
#>      N ME  MAE RMSE MaxAE  rME  rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1 9496  0 3.38 4.22 15.57 0.01 16.91 21.12  0.01 -0.98 0.39  0.29  0
#Performance for pentad values:
agreement_stats(df=pentad_means)
#>      N   ME  MAE RMSE MaxAE  rME rMAE rRMSE PBIAS NSE   d d_mod R2
#> 1 1898 0.01 1.55 1.93  6.35 0.04 7.74  9.64  0.04  -1 0.4   0.3  0
#Performance for seasonal values (Austral seasons: DJF, MAM, JJA, SON):
agreement_stats(df=seasonal_means)
#>     N   ME MAE RMSE MaxAE  rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 105 0.01 0.4 0.49  1.19 0.07 1.98  2.45  0.07 -1.34 0.22  0.19 0.05
```

## Example 4

Overall stats are great, but let’s see if model performance varies
across different seasons:

``` r
#Seasonal performance for daily values in the:
agreement_stats(df=daily_data, by_season = TRUE)
#>   season    N    ME  MAE RMSE MaxAE   rME  rMAE rRMSE PBIAS   NSE    d d_mod R2
#> 1 Autumn 2392  0.14 3.40 4.26 15.57  0.70 17.15 21.49  0.70 -1.02 0.39  0.29  0
#> 2 Spring 2366 -0.05 3.35 4.18 14.23 -0.26 16.68 20.82 -0.26 -0.99 0.39  0.29  0
#> 3 Summer 2346 -0.09 3.32 4.15 14.76 -0.43 16.54 20.68 -0.43 -0.97 0.40  0.30  0
#> 4 Winter 2392  0.01 3.45 4.29 14.80  0.04 17.24 21.46  0.04 -0.96 0.38  0.28  0
#Seasonal performance for pentad values:
agreement_stats(df=pentad_means, by_season = TRUE)
#>   season   N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 Autumn 468  0.04 1.56 1.91  6.35  0.22 7.79  9.54  0.22 -1.09 0.44  0.31 0.01
#> 2 Spring 468  0.08 1.56 1.96  5.39  0.39 7.84  9.84  0.39 -1.04 0.38  0.29 0.00
#> 3 Summer 468  0.11 1.55 1.91  5.85  0.56 7.75  9.54  0.56 -1.13 0.35  0.26 0.00
#> 4 Winter 494 -0.19 1.52 1.93  6.22 -0.93 7.60  9.63 -0.93 -0.81 0.42  0.32 0.00
#Seasonal performance for seasonal values (Austral seasons: DJF, MAM, JJA, SON):
agreement_stats(df=seasonal_means, by_season = TRUE)
#>   season  N    ME  MAE RMSE MaxAE   rME rMAE rRMSE PBIAS   NSE    d d_mod   R2
#> 1 Autumn 26  0.04 0.37 0.49  1.14  0.19 1.83  2.45  0.19 -1.52 0.28  0.26 0.07
#> 2 Spring 26  0.07 0.43 0.51  1.00  0.35 2.18  2.57  0.35 -1.86 0.14  0.13 0.16
#> 3 Summer 27  0.12 0.42 0.51  1.19  0.62 2.10  2.58  0.62 -0.76 0.23  0.17 0.01
#> 4 Winter 26 -0.18 0.37 0.44  0.98 -0.90 1.82  2.19 -0.90 -2.06 0.34  0.26 0.00
```
