test_that("Additive models show 0 interactions (univariate)", {
  fit <- lm(Sepal.Length ~ ., data = iris)
  s <- hstats(fit, X = iris[-1L], verbose = FALSE, threeway_m = 5L)
  expect_null(h2_pairwise(s, zero = FALSE)$M)
  expect_equal(c(h2_pairwise(s, sort = FALSE, top_m = Inf)$M), rep(0, choose(4, 2)))
  
  expect_null(h2_threeway(s, zero = FALSE)$M)
  expect_equal(c(h2_threeway(s, sort = FALSE, top_m = Inf)$M), rep(0, choose(4, 3)))
  
  expect_equal(
    h2_overall(s)$M, 
    matrix(c(0, 0, 0, 0), ncol = 1L, dimnames = list(colnames(iris[-1L]), NULL))
  )
  expect_null(h2_overall(s, zero = FALSE)$M)
  
  expect_equal(h2(s)$M, matrix(0, nrow = 1L, ncol = 1L))
  
  expect_s3_class(plot(h2_overall(s)), "ggplot")
  expect_s3_class(plot(s, rotate_x = TRUE), "ggplot")
  expect_message(plot(h2_overall(s, zero = FALSE)))
  
  # With quantile approximation
  s <- hstats(
    fit, X = iris[-1L], verbose = FALSE, threeway_m = 5L, approx = TRUE, grid_size = 5L,
  )
  expect_null(h2_pairwise(s, zero = FALSE)$M)
})

test_that("Additive models show 0 interactions (multivariate)", {
  fit <- lm(as.matrix(iris[1:2]) ~ Petal.Length + Petal.Width + Species, data = iris)
  s <- hstats(fit, X = iris[3:5], verbose = FALSE, threeway_m = 5)
  
  expect_null(h2_pairwise(s, zero = FALSE)$M)
  expect_true(all(h2_pairwise(s)$M == 0))
  
  expect_null(h2_threeway(s, zero = FALSE)$M)
  expect_equal(unname(h2_threeway(s)$M), cbind(0, 0))
  
  expect_equal(
    h2_overall(s, sort = FALSE)$M, 
    matrix(
      0, ncol = 2L, nrow = 3L, dimnames = list(colnames(iris[3:5]), colnames(iris[1:2]))
    )
  )
  expect_null(h2_overall(s, zero = FALSE)$M)
  
  expect_equal(h2(s)$M, rbind(c(Sepal.Length = 0, Sepal.Width = 0)))
  
  expect_s3_class(plot(h2_overall(s)), "ggplot")
  expect_message(plot(h2_overall(s, zero = FALSE)))
  expect_s3_class(plot(s), "ggplot")
})

test_that("Non-additive models show interactions > 0 (one interaction)", {
  fit <- lm(Sepal.Length ~ . + Petal.Length:Petal.Width, data = iris)
  s <- hstats(fit, X = iris[-1L], verbose = FALSE)
  expect_true(h2(s)$M > 0)
  
  out <- h2_overall(s)$M
  expect_true(
    all(rownames(out[out > 0, , drop = FALSE]) %in% c("Petal.Length", "Petal.Width"))
  )
  out <- h2_overall(s, zero = FALSE, sort = FALSE)$M
  expect_true(all(rownames(out) %in% c("Petal.Length", "Petal.Width")))

  out <- h2_pairwise(s, zero = FALSE)$M
  expect_equal(rownames(out), "Petal.Length:Petal.Width")
  out <- h2_pairwise(s)$M
  expect_equal(rownames(out[out > 0, , drop = FALSE]), "Petal.Length:Petal.Width")
  
  expect_s3_class(plot(h2_overall(s)), "ggplot")
  expect_s3_class(plot(h2_pairwise(s)), "ggplot")
  expect_s3_class(plot(s), "ggplot")
  expect_null(h2_threeway(s, zero = FALSE)$M)
  
  # With quantile approximation
  s <- hstats(fit, X = iris[-1L], verbose = FALSE, approx = TRUE, grid_size = 5L)
  expect_true(h2(s)$M > 0)
})

fit <- lm(
  Sepal.Length ~ . + Petal.Length:Petal.Width + Petal.Length:Species, data = iris
)
s <- hstats(fit, X = iris[-1L], verbose = FALSE, threeway_m = 5L)

test_that("Non-additive models show interactions > 0 (two interactions)", {
  expect_true(h2(s)$M > 0)
  
  out <- h2_overall(s, sort = FALSE, normalize = FALSE, squared = FALSE)$M
  expect_equal(
    rownames(out[out > 0, , drop = FALSE]), 
    c("Petal.Length", "Petal.Width", "Species")
  )
  out <- h2_overall(s, sort = FALSE, normalize = FALSE, squared = FALSE, zero = FALSE)$M
  expect_equal(
    rownames(out), c("Petal.Length", "Petal.Width", "Species")
  )
  
  out <- h2_pairwise(s, sort = FALSE, normalize = FALSE, squared = FALSE)$M
  expect_equal(
    rownames(out[out > 0, , drop = FALSE]), 
    c("Petal.Length:Petal.Width", "Petal.Length:Species")
  )
  out <- h2_pairwise(
    s, sort = FALSE, normalize = FALSE, squared = FALSE, zero = FALSE
  )$M
  expect_equal(
    rownames(out), c("Petal.Length:Petal.Width", "Petal.Length:Species")
  )
  
  expect_s3_class(plot(h2_overall(s)), "ggplot")
  expect_s3_class(plot(h2_pairwise(s)), "ggplot")
  expect_s3_class(plot(h2_threeway(s)), "ggplot")
  expect_message(plot(h2_threeway(s, zero = FALSE)))
  
  expect_equal(c(h2_threeway(s)$M), rep(0, choose(4, 3)))
})

test_that("passing v works", {
  s2 <- hstats(fit, X = iris[-1L], v = rev(colnames(iris[-1L])), verbose = FALSE)
  expect_equal(h2_overall(s), h2_overall(s2))
})

test_that("Case weights have an impact", {
  s1 <- s
  s1$w <- NULL
  s2 <- hstats(
    fit, X = iris[-1L], verbose = FALSE, w = rep(2, times = 150L), threeway_m = 5L
  )
  s2[["w"]] <- NULL
  expect_equal(s1, s2)
  
  capture_output(s2 <- hstats(fit, X = iris[-1L], w = 1:150))
  s2[["w"]] <- NULL
  expect_false(identical(s1, s2))
})

test_that("Case weights can be passed as colum name", {
  s2 <- hstats(fit, X = iris[-1L], verbose = FALSE, w = "Petal.Width")
  s3 <- hstats(
    fit, 
    X = iris[-1L], 
    v = setdiff(colnames(iris[-1L]), "Petal.Width"),
    verbose = FALSE, 
    w = iris$Petal.Width
  )
  s4 <- hstats(
    fit, X = iris, v = colnames(iris[-1L]), verbose = FALSE, w = "Petal.Width"
  )
  expect_identical(s2, s3)
  expect_false(identical(s2$v, s4$v))
})

test_that("print() method does not give error", {
  capture_output(expect_no_error(print(s)))
})

test_that("summary() method returns statistics", {
  expect_no_error(sm <- summary(s))
  capture_output(expect_no_error(print(sm)))
  expect_equal(sm$h2, h2(s))
  expect_equal(sm$h2_overall, h2_overall(s))
  expect_equal(sm$h2_pairwise, h2_pairwise(s))
  expect_equal(sm$h2_threeway, h2_threeway(s))
})

test_that("Stronger interactions get higher statistics", {
  pf1 <- function(m, x) x$Petal.Width + x$Petal.Width * x$Petal.Length
  pf2 <- function(m, x) x$Petal.Width + x$Petal.Width * x$Petal.Length * 2
  
  set.seed(1L)
  int1 <- hstats(1, X = iris[-1L], pred_fun = pf1, verbose = FALSE)
  set.seed(1L)
  int2 <- hstats(1, X = iris[-1L], pred_fun = pf2, verbose = FALSE)
  
  expect_true(h2(int2)$M > h2(int1)$M)
  expect_true(h2_pairwise(int2, zero = FALSE)$M > h2_pairwise(int1, zero = FALSE)$M)
})

test_that("subsampling has an effect", {
  set.seed(1L)
  out1 <- hstats(fit, X = iris[-1L], n_max = 10L, w = 1:150, verbose = FALSE)
  
  set.seed(2L)
  out2 <- hstats(fit, X = iris[-1L], n_max = 10L, w = 1:150, verbose = FALSE)
  
  expect_false(identical(out1, out2))
})

test_that("multivariate results are consistent", {
  fit <- lm(cbind(up = uptake, up2 = 2 * uptake) ~ Type * Treatment * conc, data = CO2)
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE)
  
  # Normalized
  out <- h2_pairwise(s)$M
  expect_equal(out[, "up"], out[, "up2"])
  
  # Unnormalized
  out <- h2_pairwise(s, normalize = FALSE, squared = FALSE)$M
  expect_equal(2 * out[, "up"], out[, "up2"])
})

test_that("Three-way interaction is positive in model with such terms", {
  fit <- lm(uptake ~ Type * Treatment * conc, data = CO2)
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE)
  expect_null(h2_threeway(s)$M)
  
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE, threeway_m = 5L)
  expect_true(h2_threeway(s)$M > 0)
})

test_that("Three-way interaction behaves correctly across dimensions", {
  fit <- lm(
    cbind(up = uptake, up2 = 2 * uptake) ~ Type * Treatment * conc, 
    data = CO2
  )
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE, threeway_m = 5L)
  out <- h2_threeway(s)$M
  expect_equal(out[, "up"], out[, "up2"])
  out <- h2_threeway(s, squared = FALSE, normalize = FALSE)$M
  expect_equal(2 * out[, "up"], out[, "up2"])
})

test_that("Pairwise and three-way interactions can be suppressed", {
  fit <- lm(uptake ~ Type * Treatment * conc, data = CO2)
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE)
  expect_null(h2_threeway(s)$M)
  
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE, pairwise_m = 2L)
  expect_equal(nrow(h2_pairwise(s)$M), 1L)
  expect_null(h2_threeway(s)$M)
  
  s <- hstats(fit, X = CO2[2:4], verbose = FALSE, pairwise_m = 0L)
  expect_equal(nrow(h2_overall(s)$M), 3L)
  expect_null(h2_pairwise(s)$M)
  expect_null(h2_threeway(s)$M)
})

fit <- lm(uptake ~ Type * Treatment * conc, data = CO2)
s <- hstats(fit, X = CO2[2:4], verbose = FALSE, threeway_m = 5L)

test_that("Statistics react on normalize, (sorting), squaring, and top m", {
  expect_identical(h2(s)$M, s$h2$num / s$h2$denom)
  expect_identical(h2(s, normalize = FALSE)$M, s$h2$num)
  expect_identical(h2(s, normalize = FALSE, squared = FALSE)$M, sqrt(s$h2$num))
  
  expect_identical(h2_overall(s, sort = FALSE)$M, s$h2_overall$num / s$h2_overall$denom)
  expect_identical(h2_overall(s, sort = FALSE, normalize = FALSE)$M, s$h2_overall$num)
  expect_identical(
    h2_overall(s, sort = FALSE, normalize = FALSE, squared = FALSE)$M, 
    sqrt(s$h2_overall$num)
  )
  
  expect_identical(
    h2_pairwise(s, sort = FALSE)$M, s$h2_pairwise$num / s$h2_pairwise$denom
  )
  expect_identical(h2_pairwise(s, sort = FALSE, normalize = FALSE)$M, s$h2_pairwise$num)
  expect_identical(
    h2_pairwise(s, sort = FALSE, normalize = FALSE, squared = FALSE)$M, 
    sqrt(s$h2_pairwise$num)
  )
  
  expect_identical(h2_threeway(s)$M, s$h2_threeway$num / s$h2_threeway$denom)
  expect_identical(h2_threeway(s, normalize = FALSE)$M, s$h2_threeway$num)
  expect_identical(
    h2_threeway(s, normalize = FALSE, squared = FALSE)$M, 
    sqrt(s$h2_threeway$num)
  )
})

test_that("Statistics are sorted", {
  expect_false(is.unsorted(-h2_overall(s)$M))
  expect_false(is.unsorted(-h2_pairwise(s)$M))
})

test_that("summary() reacts on normalize and squared", {
  su <- summary(s, normalize = FALSE)
  expect_identical(su$h2, h2(s, normalize = FALSE))
  expect_identical(su$h2_overall, h2_overall(s, normalize = FALSE))
  expect_identical(su$h2_pairwise, h2_pairwise(s, normalize = FALSE))
  expect_identical(su$h2_threeway, h2_threeway(s, normalize = FALSE))
  
  su <- summary(s, squared = FALSE)
  expect_identical(su$h2, h2(s, squared = FALSE))
  expect_identical(su$h2_overall, h2_overall(s, squared = FALSE))
  expect_identical(su$h2_pairwise, h2_pairwise(s, squared = FALSE))
  expect_identical(su$h2_threeway, h2_threeway(s, squared = FALSE))
})

test_that("get_v() works", {
  H <- cbind(c(a = 1, b = 3, c = 2, d = 5))
  expect_equal(get_v(H, 2L), c("b", "d"))
  expect_equal(get_v(H, 1L), "d")
  
  H <- cbind(
    x = c(a = 1, b = 3, c = 2, d = 5),
    y = 4:1
  )
  expect_equal(get_v(H, 2L), c("a", "b", "d"))
  expect_equal(get_v(H, 1L), c("a", "d"))
})

test_that("matrix case works as well", {
  X <- cbind(i = 1, data.matrix(iris[2:4]))
  fit <- lm.fit(x = X, y = iris$Sepal.Length)
  pred_fun <- function(m, X) X %*% m$coefficients
  s <- hstats(fit, X = X, v = colnames(iris[2:4]), pred_fun = pred_fun, verbose = FALSE)
  expect_equal(c(h2_overall(s)$M), c(0, 0, 0))
  
  # With quantile approximation
  s <- hstats(
    fit, 
    X = X, 
    v = colnames(iris[2:4]), 
    pred_fun = pred_fun, 
    verbose = FALSE, 
    approx = TRUE,
    grid_size = 20L
  )
  expect_equal(c(h2_overall(s)$M), c(0, 0, 0))
})

# Missing values (can give warnings from rowmean())
X <- data.frame(x1 = 1:6, x2 = c(NA, 1, 2, 1, 1, 3), x3 = factor(c("A", NA, NA, "B", "A", "A")))
fit <- "a model"
pfi <- function(fit, x) ifelse(is.na(x$x1 * x$x2), 1, x$x1 * x$x2)

test_that("hstats() does not give an error with missing", {
  expect_no_error(
    suppressWarnings(r <- hstats(fit, X = X, pred_fun = pfi, verbose = FALSE))
  )
  expect_true(drop(r$h2$num) > 0)
  expect_equal(rownames(h2_pairwise(r, zero = FALSE)), "x1:x2")
})

test_that("hstats() matches {iml} 0.11.1 in a specific case", {
  fit <- lm(Sepal.Width ~ . + Sepal.Length:Species, data = iris)
  
  # library(iml)
  # mod <- Predictor$new(fit, data = iris[-2L])
  # iml_overall <- Interaction$new(mod, grid.size = 150)
  # Sepal.Length: 0.4634029
  # iml_pairwise <- Interaction$new(mod, grid.size = 150, feature = "Species")
  # Sepal.Length:Species 0.2624154
  
  H <- hstats(fit, X = iris[-2L], verbose = FALSE)
  expect_equal(
    c(h2_overall(H, squared = FALSE)["Sepal.Length", ]$M), 
    0.4634029, 
    tolerance = 1e-5
  )
  expect_equal(
    c(h2_pairwise(H, squared = FALSE)["Sepal.Length:Species", ]$M), 
    0.2624154,
    tolerance = 1e-5
  )
})

test_that("hstats() gives all zero statistics if prediction is constant", {
  pf <- function(m, X) numeric(nrow(X))
  out <- hstats(1, X = iris[1:4], pred_fun = pf, verbose = FALSE)

  expect_equal(h2(out)$M, matrix(0))
  expect_equal(out$h2$num / out$h2$denom, matrix(NaN))
  
  expect_equal(c(h2_overall(out)$M), c(0, 0, 0, 0))
  expect_equal(out$mean_f2, 0)
  expect_equal(out$h2_overall$denom, out$mean_f2)
  expect_equal(out$pd_importance$denom, 0)
  
  expect_equal(c(h2_pairwise(out)$M), rep(0, choose(4, 2)))
  expect_equal(c(out$h2_pairwise$denom), rep(1, choose(4, 2)))
})

test_that("behavior is ok if one dim is constant and other not", {
  pf <- function(m, X) cbind(0, X$Sepal.Length * X$Petal.Length)
  out <- hstats(1, X = iris[1:4], pred_fun = pf, verbose = FALSE)
  
  expect_equal(c(h2(out)$M == 0), c(TRUE, FALSE))
  expect_equal(out$h2$num[1L] / out$h2$denom[1L], NaN)
  
  ex <- rbind(
    Sepal.Length = c(TRUE, FALSE),
    Sepal.Width = c(TRUE, TRUE),
    Petal.Length = c(TRUE, FALSE),
    Petal.Width = c(TRUE, TRUE)
  )
  expect_equal(h2_overall(out, sort = FALSE)$M == 0, ex)
  expect_equal(out$mean_f2 == 0, c(TRUE, FALSE))
  expect_equal(out$h2_overall$denom, out$mean_f2)
  
  rs <- rowSums(h2_pairwise(out, sort = FALSE)$M) > 0
  pos <- "Sepal.Length:Petal.Length"
  
  expect_equal(row.names(h2_pairwise(out, sort = FALSE)$M[rs, , drop = FALSE]), pos)
  expect_equal(out$h2_pairwise$denom[rs, ] == 0, c(TRUE, FALSE))
  expect_true(all(out$h2_pairwise$denom[!rs, ] == 1))
})
