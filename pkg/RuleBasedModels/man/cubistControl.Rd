\name{cubistControl}
\alias{cubistControl}
\title{
Various parameters that control aspects of the Cubist fit.
}
\description{
Various parameters that control aspects of the Cubist fit.
}
\usage{
cubistControl(unbiased = FALSE, 
              composite = "auto", 
              neighbors = 3,
              committees = 1, 
              rules = NA, 
              extrapolation = 100,
              sample = 99.9, 
              seed = 1,
              label = "outcome")
}
\arguments{
  \item{unbiased}{
a logical: should unbiased rules be used?
}
  \item{composite}{
either "yes", "no" or "auto" to control whether Cubist should suppliment the rule-based model predicitons using additional data from the training set instances. See Quinlan (1993) for more details.
}
  \item{neighbors}{
If instances are used, how many neighbors are evaluate to adjust the rule-based prediction? Values should be between 1 and 9
}
  \item{committees}{
an integer: how many committee models (e.g.. boosting iterations) should be used?
}
  \item{rules}{
an integer (or \code{NA}): define an explicit limit to the number of rules used (\code{NA} let's Cubist decide).
}
  \item{extrapolation}{
a number between 0 and 100: since Cubist uses linear models, predictions can be outside of the outside of the range seen the training set. This parameter controls how much rule predictions are adjusted to be consistent with the training set.  
}
  \item{sample}{
a number between 0.01 and 100: this is the percentage of the data set to be randomly selected for model building and for out-of-bag type evaluation.
}
  \item{seed}{
an integer for the random seed (in the C code)
}
  \item{label}{
a label for the outcome (when printing rules)
}
}
\details{
Most of these values are discussed at length in \url{http://rulequest.com/cubist-unix.html}
}
\value{
A list containing the options.
}
\references{
Quinlan. Combining instance-based and model-based learning. Proceedings of the Tenth International Conference on Machine Learning (1993) pp. 236-243
}
\author{
Max Kuhn
}

\seealso{
\code{\link{cubist}}
}
\examples{
cubistControl()
}

\keyword{ utilities}

