% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_grid.R
\name{univariate_grid}
\alias{univariate_grid}
\title{Univariate Grid}
\usage{
univariate_grid(
  z,
  grid_size = 49L,
  trim = c(0.01, 0.99),
  strategy = c("uniform", "quantile"),
  na.rm = TRUE
)
}
\arguments{
\item{z}{A vector or factor.}

\item{grid_size}{Approximate grid size.}

\item{trim}{The default \code{c(0.01, 0.99)} means that values outside the
1\% and 99\% quantiles of non-discrete numeric columns are removed before calculation
of grid values. Set to \code{0:1} for no trimming.}

\item{strategy}{How to find grid values of non-discrete numeric columns?
Either "uniform" or "quantile", see description of \code{\link[=univariate_grid]{univariate_grid()}}.}

\item{na.rm}{Should missing values be dropped from the grid? Default is \code{TRUE}.}
}
\value{
A vector or factor of evaluation points.
}
\description{
Creates evaluation grid for any numeric or non-numeric vector \code{z}.

For discrete \code{z} (non-numeric, or numeric with at most \code{grid_size} unique values),
this is simply \code{sort(unique(z))}.

Otherwise, if \code{strategy = "uniform"} (default), the evaluation points form a regular
grid over the trimmed range of \code{z}. By trimmed range we mean the
range of \code{z} after removing values outside \code{trim[1]} and \code{trim[2]} quantiles.
Set \code{trim = 0:1} for no trimming.

If \code{strategy = "quantile"}, the evaluation points are quantiles over a regular grid
of probabilities from \code{trim[1]} to \code{trim[2]}.

Quantiles are calculated via the inverse of the ECDF, i.e., via
\verb{stats::quantile(..., type = 1}).
}
\examples{
univariate_grid(iris$Species)
univariate_grid(rev(iris$Species))                       # Same

x <- iris$Sepal.Width
univariate_grid(x, grid_size = 5)                        # Uniform binning
univariate_grid(x, grid_size = 5, strategy = "quantile")  # Quantile
}
\seealso{
\code{\link[=multivariate_grid]{multivariate_grid()}}
}
