\name{C5.0.default}
\alias{C5.0.default}
\alias{C5.0}
\title{
C5.0 Decision Trees and Rule-Based Models
}
\description{
Fit classification tree models or rule-based models using Quinlan's
C5.0 algorithm
}
\usage{
C5.0(x, ...)

\method{C5.0}{default}(x, y, trials = 1, rules= FALSE, 
     weights = NULL, 
     control = C5.0Control(), 
     costs = NULL, ...)
}

\arguments{
  \item{x}{
a data frame or matrix of predictors.
}
  \item{y}{
a factor vector with 2 or more levels
}
  \item{trials}{
an integer specifying the number of boosting iterations. A value of
one indicates that a single model is used.
}
  \item{rules}{
A logical: should the tree be decomposed into a rule-based model?
}
  \item{weights}{
an optional numeric vector of case weights
}
  \item{control}{
a list of control parameters; see \code{\link{C5.0Control}}
}
  \item{costs}{
a matrix of costs associated with the possible errors. The matrix
should have C columns and rows where C is the number of class levels.
}
  \item{\dots}{
other options to pass into the function (not currently used)
}
}
\details{
This model extends the C4.5 classification algorithms described in
Quinlan (1992). The details of the extensions are largely
undocumented.

The model can take the form of a full decision tree or a collection of
rules.

C5.0 contains an option for boosting.

}
\value{
An object of class \code{C5.0} with elements:
}
\references{
Quinlan R (1993). C4.5: Programs for Machine Learning. Morgan Kaufmann Publishers,
\url{http://www.rulequest.com/see5-unix.html}
}
\author{
Original GPL C code by Ross Quinlan, R code and modifications to C by
Max Kuhn, Steve Weston and Nathan Coulter
}
\note{
not all data types are supported 

No formula method
}

\seealso{
\code{\link{C5.0Control}}, \code{\link{summary.C5.0}}, \code{\link{predict.C5.0}}, \code{\link{C5imp}}
}
\examples{
data(churn)

treeModel <- C5.0(x = churnTrain[, -20], y = churnTrain$churn)
treeModel
summary(treeModel)

ruleModel <- C5.0(x = churnTrain[, -20], y = churnTrain$churn, rules = TRUE)
ruleModel
summary(ruleModel)
}


\keyword{ models }