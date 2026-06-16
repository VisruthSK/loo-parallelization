library(brms)

wine_scaled <- read.delim(
  "https://archive.ics.uci.edu/ml/machine-learning-databases/wine-quality/winequality-red.csv",
  sep = ";"
) |>
  unique() |>
  scale() |>
  as.data.frame()

wine_fit <- brm(
  ordered(quality) ~ .,
  family = cumulative("logit"),
  prior = prior(R2D2(mean_R2 = 1 / 3, prec_R2 = 3)),
  data = wine_scaled,
  seed = 1,
  silent = 2,
  refresh = 0,
  cores = 4,
  backend = "cmdstanr"
)

log_lik_matrix <- log_lik(wine_fit)

saveRDS(log_lik_matrix, "data/wine_ll.rds")

profile_wrap <- function(cores) {
  htmlwidgets::saveWidget(
    profvis::profvis(loo::loo(log_lik_matrix, cores = cores)),
    glue::glue("profiles/profile_parallel_{cores}.html")
  )
  invisible(cores)
}

vapply(1:4, profile_wrap, numeric(1))
