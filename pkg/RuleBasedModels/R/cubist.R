cubist <-  function(x, ...) UseMethod("cubist")

## About the Cubist C code and our approach here...

## 1) The cubist code is written to take specific data files from the file system,
## pull them into memory, run the computations, then write the results to a text
## file that is also saved to the file system.
##
## 2) The code makes use of a lot of global variables (especially for the data)
##
## 3). The code has been around for a while and, after reading it, one can tell
## that the author put in a lot of time to catch many special cases. We have
## pushed millions of samples through the code without any errors
##
## So... the approach here is to pass in the training data as strings that mimic
## the formats that one would use with the command line version and get back the
## textual representation that would be saved to the .model file also as a string.
## The predicton function would then pass the model text string (and the data text
## string if instances are used) to the C code for prediciton.
##
## We did this for a few reasons:
##
## a) this approach would require us to re-write main() and touch as little of the
## original code as possible (otherwise we would have to write a parser for the
## data and try to get it into the global variable structure with complete fidelity)
##
## b) most modeling functions implicitly assume that the data matrix is all numeric,
## thus factors are converted to dummy variables etc. Cubist doesn't want categorical
## data split into dummy variables based on how it does splits. Thus, we would have
## to pass in the numeric and categorical predictors separately unless we want to
## get really fancy.

cubist.default <- function(x, y, control = cubistControl(), ...)
{
  funcCall <- match.call(expand.dots = TRUE)
  if(!is.numeric(y)) stop("cubist models require a numeric outcome")

  ## TODO: check for missing outcome data
  
  namesString <- makeNamesFile(x, y, label = control$label, comments = TRUE)
  dataString <- makeDataFile(x, y)

  ## TODO: figure out how to combine the combinations of -i and -a

  Z <- .C("cubist",
          as.character(namesString),
          as.character(dataString),
          as.logical(control$unbiased),     # -u : generate unbiased rules
          as.character(control$composite),  # -i and -a : how to combine these?
          as.integer(control$neighbors),    # -n : set the number of nearest neighbors (1 to 9)
          as.integer(control$committees),   # -c : construct a committee model
          as.double(control$sample),        # -S : use a sample of x% for training
                                            #      and a disjoint sample for testing
          as.integer(control$seed),         # -I : set the sampling seed value
          as.integer(control$rules),        # -r: set the maximum number of rules
          as.double(control$extrapolation), # -e : set the extrapolation limit
          model=character(1),               # pass back .model file as a string
          output=character(1),              # pass back cubist output as a string
          PACKAGE="RuleBasedModels"
          )
  cat(Z$model, '\n')
  cat(Z$output, '\n')
  
  out <- list(data = dataString,
              names = namesString,
              control = control,
              dims = dim(x),
              call = funcCall)
  class(out) <- "cubist"
  out
}
 

testcubist <- function()
  {
    ## testing example
    cubist(iris[,-1], iris[,1])
  }

cubistControl <- function(unbiased = FALSE,
                          composite = "auto",
                          neighbors = 3,
                          committees = 1,
                          rules = 100,
                          extrapolation = 100,
                          sample = 99.9,
                          seed = sample.int(4096, size=1) - 1L,
                          label = "outcome")
  {
    if(!is.na(rules) & (rules < 1 | rules > 1000000))
      stop("number of rules must be between 1 and 1000000")
    if(extrapolation < 0 | extrapolation > 100)
      stop("percent extrapolation must between 0 and 100")
    if(neighbors < 1 | neighbors > 9)
      stop("number of neighbors must be between 1 and 9")
    if(sample < 0.1 | sample > 99.9)
      stop("sampling percentage must be between 0.1 and 99.9")
    if(committees < 1 | committees > 100)
      stop("number of committees must be between 1 and 100")

    list(unbiased = unbiased,
         composite = composite,
         neighbors = neighbors,
         committees = committees,
         rules = rules,
         extrapolation = extrapolation / 100,
         sample = sample / 100,
         label = label,
         seed = seed %% 4096L)
  }


print.cubist <- function(x, ...)
  {
    cat("\nCall:\n", truncateText(deparse(x$call, width.cutoff = 500)), "\n\n", sep = "")


    cat("Number of samples:", x$dims[1],
        "\nNumber of predictors:", x$dims[2],
        "\n\n")
    
    if(x$control$composite == "yes") cat("Rule and Instance-Based Model\n") else cat("Rule-Based Model\n") 
    
    cat("Number of Rules:", 0, "\n")
    cat("Number of Committees:", x$control$committees, "\n")
    if(x$control$composite == "yes") cat("Number of Instances:", x$control$neighbors, "\n")
    otherOptions <- NULL
    if(x$control$unbiased) otherOptions <- c(otherOptions, "unbiased rules")
    if(x$control$extrapolation < 100) otherOptions <- c(otherOptions,
                                                        paste(x$control$extrapolation, "% extrapolation", sep = ""))
    if(x$control$sample < 99.9) otherOptions <- c(otherOptions,
                                                        paste(x$control$sample, "% sub-sampling", sep = ""))
    if(!is.null(otherOptions))
      {
        cat("Other options:", paste(otherOptions, collapse = ", "))
      }
    

  }



truncateText <- function(x)
  {
    if(length(x) > 1) x <- paste(x, collapse = "")
    w <- options("width")$width
    if(nchar(x) <= w) return(x)

    cont <- TRUE
    out <- x
    while(cont)
      {
        
        tmp <- out[length(out)]
        tmp2 <- substring(tmp, 1, w)
        
        spaceIndex <- gregexpr("[[:space:]]", tmp2)[[1]]
        stopIndex <- spaceIndex[length(spaceIndex) - 1] - 1
        tmp <- c(substring(tmp2, 1, stopIndex),
               substring(tmp, stopIndex + 1))
        out <- if(length(out) == 1) tmp else c(out[1:(length(x)-1)], tmp)
        if(all(nchar(out) <= w)) cont <- FALSE
      }

    paste(out, collapse = "\n")
  }

