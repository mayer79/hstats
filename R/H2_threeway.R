#' Three-way Interaction Strength
#' 
#' Friedman and Popescu's statistic of three-way interaction strength extracted from the
#' result of [interact()], see Details. By default, the results are plotted as barplot.
#' Set `plot = FALSE` to get numbers.
#' 
#' @details
#' Friedman and Popescu (2008) describe a test statistic to measure three-way 
#' interactions: in case there are no three-way interactions between features 
#' \eqn{x_j}, \eqn{x_k} and \eqn{x_l}, their (centered) three-dimensional partial 
#' dependence function \eqn{F_{jkl}} can be decomposed into lower order terms:
#' \deqn{
#'   F_{jkl}(x_j, x_k, x_l) = B_{jkl} - C_{jkl}
#' }
#' with
#' \deqn{
#'   B_{jkl} = F_{jk}(x_j, x_k) + F_{jl}(x_j, x_l) + F_{kl}(x_k, x_l)
#' }
#' and
#' \deqn{
#'   C_{jkl} =  F_j(x_j) + F_k(x_k) + F_l(x_l).
#' }
#' 
#' The squared and scaled difference between the two sides of the equation leads to the statistic
#' \deqn{
#'   H_{jkl}^2 = \frac{\frac{1}{n} \sum_{i = 1}^n \big[\hat F_{jkl}(x_{ij}, x_{ik}, x_{il}) - B^{(i)}_{jkl} + C^{(i)}_{jkl}\big]^2}{\frac{1}{n} \sum_{i = 1}^n \hat F_{jkl}(x_{ij}, x_{ik}, x_{il})^2},
#' }
#' where
#' \deqn{
#'   B^{(i)}_{jkl} = \hat F_{jk}(x_{ij}, x_{ik}) + \hat F_{jl}(x_{ij}, x_{il}) + 
#'   \hat F_{kl}(x_{ik}, x_{il})
#' }
#' and
#' \deqn{
#'   C^{(i)}_{jkl} = \hat F_j(x_{ij}) + \hat F_k(x_{ik}) + \hat F_l(x_{il}).
#' }
#' Similar remarks as for [H2_pairwise()] apply.
#' 
#' @inheritParams H2_overall
#' @returns 
#'   A matrix of statistics (one row per variable, one column per prediction dimension),
#'   or a "ggplot" object (if `plot = TRUE`). If no three-way
#'   statistics have been calculated, the function returns `NULL`.
#' @inherit interact references
#' @export
#' @seealso [interact()], [H2()], [H2_overall()], [H2_pairwise()]
#' @examples
#' # MODEL 1: Linear regression
#' fit <- lm(uptake ~ Type * Treatment * conc, data = CO2)
#' inter <- interact(fit, v = names(CO2[2:4]), X = CO2, verbose = FALSE)
#' H2_threeway(inter, plot = FALSE)
#' 
#' #' MODEL 2: Multivariate output (taking just twice the same response as example)
#' fit <- lm(cbind(up = uptake, up2 = 2 * uptake) ~ Type * Treatment * conc, data = CO2)
#' inter <- interact(fit, v = names(CO2[2:4]), X = CO2, verbose = FALSE)
#' H2_threeway(inter, plot = FALSE)
#' 
#' # Unnormalized H
#' H2_threeway(inter, normalize = FALSE, squared = FALSE, plot = FALSE)
H2_threeway <- function(object, ...) {
  UseMethod("H2_threeway")
}

#' @describeIn H2_threeway Default pairwise interaction strength.
#' @export
H2_threeway.default <- function(object, ...) {
  stop("No default method implemented.")
}

#' @describeIn H2_threeway Pairwise interaction strength from "interact" object.
#' @export
H2_threeway.interact <- function(object, normalize = TRUE, squared = TRUE, sort = TRUE, 
                                 top_m = 15L, eps = 1e-8, plot = TRUE, 
                                 fill = "#2b51a1", ...) {
  combs <- object[["combs3"]]
  
  if (is.null(combs)) {
    return(NULL)
  }
  
  # Note that the F_jkl are in the same order as combs
  num <- denom <- with(
    object,
    matrix(
      nrow = length(combs), ncol = K, dimnames = list(names(combs), pred_names)
    )
  )
  
  for (i in seq_along(combs)) {
    z <- combs[[i]]
    zz <- sapply(utils::combn(z, 2L, simplify = FALSE), paste, collapse = ":")

    num[i, ] <- with(
      object, 
      wcolMeans((F_jkl[[i]] - Reduce("+", F_jk[zz]) + Reduce("+", F_j[z]))^2, w = w)
    )
    denom[i, ] <- if (normalize) with(object, wcolMeans(F_jkl[[i]]^2, w = w)) else 1
  }
  out <- postprocess(
    num = num,
    denom = denom,
    normalize = normalize, 
    squared = squared, 
    sort = sort, 
    top_m = top_m, 
    eps = eps
  )
  if (plot) plot_stat(out, fill = fill, ...) else out
}