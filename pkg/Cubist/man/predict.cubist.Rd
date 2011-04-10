\name{predict.cubist}
\alias{predict.cubist}
\title{
Predict method for cubist fits
}
\description{
Predicted values based on a cubist object.
}
\usage{
\method{predict}{cubist}(object, newdata = NULL, neighbors = object$neighbors, ...)
}
\arguments{
  \item{object}{
an object of class \code{cubist}
}
  \item{newdata}{
a data frame of predictors (in the same order as the original training data)
}
  \item{neighbors}{
the number of instances used to adjust the rule-based prediction. Note that, by default, it follows the value given in the call to \code{\link{cubist}}, but other values can be used as well (since the rules and instance adjustment are independent).
}
  \item{\dots}{
other options to pass through the function (not currently used)
}
}
\details{
Prediction using the parametric model are calculated using the method of Quinlan (1992). If \code{neighbors} is greater than zero, these predictions are adjusted by training set instances nearby using the approach of Qunilan (1993).

When \code{newdata} is \code{NULL}, the predictions fro the training set are returned.

}
\value{
a numeric vector is returned
}
\references{
Quinlan. Learning with continuous classes. Proceedings of the 5th Australian Joint Conference On Artificial Intelligence (1992) pp. 343-348

Quinlan. Combining instance-based and model-based learning. Proceedings of the Tenth International Conference on Machine Learning (1993) pp. 236-243

Quinlan. \strong{C4.5: Programs For Machine Learning} (1993) Morgan Kaufmann Publishers Inc. San Francisco, CA

\url{http://rulequest.com/cubist-info.html}

}

\author{
R code by Max Kuhn, original C sources by R Quinlan and modifications be Steve Weston
}

\seealso{
\code{\link{cubist}}, \code{\link{cubistControl}}, \code{\link{summary.cubist}}, \code{\link{predict.cubist}}, \code{\link{dotplot.cubist}}
}
\examples{
library(mlbench)
data(BostonHousing)

## 1 committee and no instance-based correction, so just an M5 fit:
mod1 <- cubist(x = BostonHousing[, -14], y = BostonHousing$medv)
predict(mod1, BostonHousing[1:4, -14])
## predict(mod1, BostonHousing[1:4, -14], neighbors = 3)

}

\keyword{models}
