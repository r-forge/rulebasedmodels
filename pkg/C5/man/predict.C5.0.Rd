\name{predict.C5.0}
\alias{predict.C5.0}
\title{
Predict new samples using a C5.0 model
}
\description{
This function produces predicted classes or confidence values from a C5.0 model.
}
\usage{
\method{predict}{C5.0}(object, newdata = NULL, 
        trials = object$trials["Actual"],
        type = "class", ...)
}

\arguments{
  \item{object}{
an object of class \code{C5.0}
}
  \item{newdata}{
a matrix or data frame of predictors
}
  \item{trials}{an integer for how many boosting iterations are used
for prediction. See the note below.  }


  \item{type}{
either \code{"class"} for the predicted class or \code{"prob"} for model confidence values.
}
  \item{\dots}{
other options (not currently used)
}
}
\details{
Note that the number of trials in the object my be less than what was
specified originally. If the number requested is larger than the
actual number available, the maximum actual is used and a warning is
issued.

Model confidence values reflect the distribution of the classes in
terminal nodes or within rules. For single trees or rule-based models
(i.e. not boosted), the predicted confidence value is the confidence
value form the most specific, active rule. Note that C4.5 sorts the
rules, and uses the first active rule for prediction.

For boosting, the per-class confidence values are aggregated over all
of the trees created during the boosting process and these aggregate
values are normalized so that the overall per-class confidence values
sum to one.  }


\value{
when \code{type = "class"}, a factor vector is returned. When \code{type = "prob"}, a matrix of confidence values is returned (one column per class). 
}
\references{
Quinlan R (1993). C4.5: Programs for Machine Learning. Morgan Kaufmann Publishers,
\url{http://www.rulequest.com/see5-unix.html}
}
\author{
Original GPL C code by Ross Quinlan, R code and modifications to C by
Max Kuhn and Steve Weston
}


\seealso{
\code{\link{C5.0}}, \code{\link{C5.0Control}}, \code{\link{summary.C5.0}},  \code{\link{C5imp}}
}
\examples{
data(churn)

treeModel <- C5.0(x = churnTrain[, -20], y = churnTrain$churn)
predict(treeModel, head(churnTest[, -20]))
predict(treeModel, head(churnTest[, -20]), type = "prob")


}

\keyword{ models }