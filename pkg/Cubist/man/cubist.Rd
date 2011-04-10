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

\method{cubist}{default}(x, y, 
       composite = "no",
       neighbors = 0,
       committees = 1,
       control = cubistControl(), ...)
}
\arguments{
  \item{x}{
a matrix or data frame of predictor variables. Missing data are allowed but (at this time) only numeric, character and factor values are allowed.
}
  \item{y}{
a numeric vector of outcome
}
  \item{composite}{
either "yes", "no" or "auto" to control whether Cubist should supplement the rule-based model predictions using additional data from the training set instances. See Quinlan (1993) for more details.
}
  \item{neighbors}{
If instances are used, how many neighbors are evaluate to adjust the rule-based prediction? Values should be between 1 and 9
}
  \item{committees}{
an integer: how many committee models (e.g.. boosting iterations) should be used?
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


The development of the rules are not affected by the choice of whether to use the instance adjustment. Cubist can use the argument \code{committees} to determine if it is empirically better to used instances or not and make it's own choice (when \code{committees = "auto"}). As such, even though there is an argument \code{neighbors} in \code{cubist}, the decision on instances is not needed until the time of prediction and can be over-ridden in \code{\link{predict.cubist}}.

Note that if the options for \code{neighbors} and \code{committees} conflict, \code{committees} will be adjusted to be consistent with the values in \code{neighbors} (with a warning).

}
\value{
an object of class \code{cubist} with elements:
  \item{data, names, model}{character strings that correspond to their counterparts for the command-line program available from RuleQuest}
  \item{output}{basic cubist output captured from the C code, including the rules, their terminal models and variable usage statistics}
  \item{control}{a list of control parameters passed in by the user}
  \item{composite, neighbors, committees}{mirrors of the values to these arguments that were passed in by the user}
  \item{dims}{the output if \code{dim(x)}}
  \item{splits}{information about the variables and values used in the rule conditions}
  \item{call}{the function call}
  \item{coefs}{a data frame of regression coefficients for each rule within each committee}
  \item{vars}{a list with elements \code{all} and \code{used} listing the predictors passed into the function and used by any rule or model}
  \item{fitted.values}{a numeric vector of predictions on the training set.}
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
\code{\link{cubistControl}}, \code{\link{predict.cubist}}, \code{\link{summary.cubist}}, \code{\link{predict.cubist}}, \code{\link{dotplot.cubist}}
}
\examples{
library(mlbench)
data(BostonHousing)

## 1 committee and no instance-based correction, so just an M5 fit:
mod1 <- cubist(x = BostonHousing[, -14], y = BostonHousing$medv)
mod1

## Now with 10 committees
mod2 <- cubist(x = BostonHousing[, -14], y = BostonHousing$medv, committees = 10)
mod2
}

\keyword{models}
