\name{NEWS}
\title{Cubist News}

\section{Version 0.0.9: 2012-02-13}{
cubist uses a string buffer to capture the output files that would
normally get saved to external files. The packge was failing R CMD
check only on windows because the output files were getting garbled.

s*printf functions work differently on Windows. On Linux, they return 
the size that is needed to correctly print the string.  On Windows,
if there isn't enough space, they return -1.  

Also, work-arounds were added to the C sources because of R CMD check
issues. printf(), assert() and exist() statements were removed or
redefined.
  }

\section{Version 0.0.8: 2011-06-21}{
    A bug was fixed for the \code{coef} method.
  }

\section{Version 0.0.6: 2011-04-28}{
    The GPL version was revised to be version 3 (thanks to Ross Quinlan for the note).

    The variable usage statistics were saved to a data frame in called \code{object$usage}. The package vignette and help files were updated accordingly.

    When using \code{cubist}, if \code{x} was a vector or a single variable, an error occurred. This was fixed.

    The vignette was also expanded to show how \pkg{caret} can be used to tune the model and a technical error was corrected about the boosting algorithm (thanks again to Ross Quinlan).
  }

\section{Initial Version: 2011-04-22}{
    The package is being submitted to CRAN
  }

