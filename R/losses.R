#' Squared Error Loss
#' 
#' Internal function. Calculates squared error.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric vector/matrix, or factor.
#' @param predicted A numeric vector/matrix, or factor.
#' @returns Vector or matrix of numeric losses.
loss_squared_error <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual, ohe = TRUE))
  predicted <- prepare_pred(predicted, ohe = TRUE)

  (actual - predicted)^2
}

#' Absolute Error Loss
#' 
#' Internal function. Calculates absolute error.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric vector/matrix.
#' @param predicted A numeric vector/matrix.
#' @returns Vector or matrix of numeric losses.
loss_absolute_error <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual))
  predicted <- prepare_pred(predicted)
  if (is.factor(actual) || is.factor(predicted)) {
    stop("Absolute loss does not make sense for factors.")
  }
  
  abs(actual - predicted)
}

#' Poisson Deviance Loss
#' 
#' Internal function. Calculates Poisson deviance.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric vector/matrix with non-negative values.
#' @param predicted A numeric vector/matrix with non-negative values.
#' @returns Vector or matrix of numeric losses.
loss_poisson <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual))
  predicted <- prepare_pred(predicted)
  if (is.factor(actual) || is.factor(predicted)) {
    stop("Poisson loss does not make sense for factors.")
  }
  stopifnot(
    all(predicted >= 0),
    all(actual >= 0)
  )
  
  out <- predicted
  p <- actual > 0
  out[p] <- (actual * log(actual / predicted) - (actual  - predicted))[p]
  2 * out
}

#' Gamma Deviance Loss
#' 
#' Internal function. Calculates Gamma deviance.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric vector/matrix with positive values.
#' @param predicted A numeric vector/matrix with positive values.
#' @returns Vector or matrix of numeric losses.
loss_gamma <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual))
  predicted <- prepare_pred(predicted)
  if (is.factor(actual) || is.factor(predicted)) {
    stop("Gamma loss does not make sense for factors.")
  }
  stopifnot(
    all(predicted > 0), 
    all(actual > 0)
  )
  
  -2 * (log(actual / predicted) - (actual - predicted) / predicted)
}

#' Classification Error Loss
#' 
#' Internal function. Calculates per-row misclassification errors.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A vector/factor/matrix with discrete values.
#' @param predicted A vector/factor/matrix with discrete values.
#' @returns Vector or matrix of numeric losses.
loss_classification_error <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual))
  predicted <- prepare_pred(predicted)
  
  (actual != predicted) * 1.0
}

#' Log Loss
#' 
#' Internal function. Calculates log loss, which is equivalent to binary cross-entropy 
#' and half the Bernoulli deviance.
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric vector/matrix with values between 0 and 1.
#' @param predicted A numeric vector/matrix with values between 0 and 1.
#' @returns Vector or matrix of numeric losses.
loss_logloss <- function(actual, predicted) {
  actual <- drop(prepare_pred(actual))
  predicted <- prepare_pred(predicted)
  if (is.factor(actual) || is.factor(predicted)) {
    stop("Log loss does not make sense for factors.")
  }
  stopifnot(
    all(predicted >= 0), 
    all(predicted <= 1),
    all(actual >= 0),
    all(actual <= 1)
  )
  
  -xlogy(actual, predicted) - xlogy(1 - actual, 1 - predicted)
}

#' Multi-Column Log Loss
#' 
#' Internal function. Log loss for probabilistic classification models with more than
#' one prediction column (one per category).
#' 
#' @noRd
#' @keywords internal
#'
#' @param actual A numeric matrix with values between 0 and 1, or a 
#'   discrete vector that will be one-hot-encoded by a fast version of
#'   `model.matrix(~ as.factor(actual) + 0)`.
#'   The column order of `predicted` must be in line with this!
#' @param predicted A numeric matrix with values between 0 and 1.
#' @returns `TRUE` (or an error message).
loss_mlogloss <- function(actual, predicted) {
  actual <- prepare_pred(actual)
  predicted <- prepare_pred(predicted)
  if (NCOL(actual) == 1L) {  # not only for factors
    actual <- fdummy(actual)
  }
  stopifnot(
    is.matrix(predicted),
    ncol(predicted) >= 2L,
    ncol(actual) == ncol(predicted),
    all(predicted >= 0), 
    all(predicted <= 1),
    all(actual >= 0),
    all(actual <= 1)
  )
  
  unname(-rowSums(xlogy(actual, predicted)))
}

#' Calculates x*log(y)
#' 
#' Internal function. Returns 0 whenever x = 0 and y >= 0.
#' 
#' @noRd
#' @keywords internal
#'
#' @param x A numeric vector/matrix.
#' @param y A numeric vector/matrix.
#' @returns A numeric vector or matrix.
xlogy <- function(x, y) {
  out <- x * log(y)
  out[x == 0] <- 0
  return(out)
}

#' String to function
#' 
#' Internal function that turns a string like "squared_error" into the corresponding
#' loss function.
#' 
#' @noRd
#' @keywords internal
#'
#' @param loss A string.
#' @returns A function.
get_loss_fun <- function(loss) {
  switch(
    loss,
    squared_error = loss_squared_error,
    logloss = loss_logloss,
    mlogloss = loss_mlogloss,
    poisson = loss_poisson,
    gamma = loss_gamma,
    absolute_error = loss_absolute_error,
    classification_error = loss_classification_error,
    stop("Unknown loss function.")
  )
}
