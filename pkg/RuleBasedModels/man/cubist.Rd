\name{cubist.default}
\alias{cubist}
\alias{cubist.default}
\title{
Fit a Cubist model
}
\description{
This function fits the rule-based model described in Quinlan (1992) (aka M5) with additional corrections based on nearest neighbors in the training set,  as described in Quinlan (1993).

}
\usage{
cubist(x, ...)

\method{cubist}{default}(x, y, control = cubistControl(), ...)
}
\arguments{
  \item{x}{
a matrix or data frame of predictor variables. Missing data are allowed but (at this time) only numeric, character and factor values are allowed.
}
  \item{y}{
a numeric vector of outcome
}
  \item{control}{
options that control details of the \code{cubist} algorithm. See \code{\link{cubistControl}}
}
  \item{\dots}{
optional arguments to pass (not currently used)
}
}
\details{
outline the algorithm here


}
\value{
an object of class \code{cubist}
}
\references{
Quinlan. Learning with continuous classes. Proceedings of the 5th Australian Joint Conference On Artificial Intelligence (1992) pp. 343-348

Quinlan. Combining instance-based and model-based learning. Proceedings of the Tenth International Conference on Machine Learning (1993) pp. 236-243

\url{http://rulequest.com/cubist-info.html}

}
\author{
R code by Max Kuhn, original C sources by R Quinlan and modifications be Steve Weston
}

\seealso{
\code{\link{cubistControl}}
}
\examples{
## none yet
}

\keyword{models }
