C5.0 <-  function(x, ...) UseMethod("C5.0")

C5.0.default <- function(x, y,
                         trials = 1,
                         weights = NULL,
                         control = C5.0Control(),
                         costs = NULL,
                         ...)
{
  funcCall <- match.call(expand.dots = TRUE)
  if(!is.factor(y)) stop("C5.0 models require a factor outcome")


  ## to do add weightings
  
  lvl <- levels(y)
  nClass <- length(lvl)
  if(!is.null(costs))
    {
      if(!is.matrix(costs)) stop("'costs' should be a matrix")
      if(ncol(costs) != nClass | nrow(costs) != nClass)
        stop(paste("'cost should be a ", nClass, "x", nClass,
                   "matrix", sep = ""))
      if(is.null(dimnames(costs)))
        {
          warning("\nno dimnames were given for the cost matrix; the factor levels will be used\n")
          colnames(costs) <- lvl
          rownames(costs) <- lvl
        } else {
          if(is.null(colnames(costs)) | is.null(rownames(costs))) stop("both row and column names are needed")    
        }
      costString <- makeCostFile(costs)
    } else costString <- ""

  if(trials < 1 | trials > 1000)
    stop("number of boosting iterations must be between 1 and 100")

  if(!is.data.frame(x) & !is.matrix(x)) stop("x must be a matrix or data frame")

  if(!is.null(weights) && !is.numeric(weights))
    stop("case weights must be numeric")
  
  ## TODO: add case weights to these files when needed
  namesString <- makeNamesFile(x, y, label = control$label, comments = TRUE)
  dataString <- makeDataFile(x, y)

  Z <- .C("C50",
          as.character(namesString),
          as.character(dataString),
          as.character(costString),
          as.logical(control$subset),       # -s "use the Subset option" var name: SUBSET
          as.logical(control$rules),        # -r "use the Ruleset option" var name: RULES
          
          ## for the bands option, I'm not sure what the default should be.
          as.integer(control$bands),        # -u "sort rules by their utility into bands" var name: UTILITY
          
          ## The documentation has two options for boosting:
          ## -b use the Boosting option with 10 trials
          ## -t trials ditto with specified number of trial
          ## I think we should use -t
          as.integer(trials),               # -t : " ditto with specified number of trial", var name: TRIALS

          as.logical(control$winnow),       # -w "winnow attributes before constructing a classifier" var name: WINNOW 
          as.double(control$sample),        # -S : use a sample of x% for training
                                            #      and a disjoint sample for testing var name: SAMPLE
          as.integer(control$seed),         # -I : set the sampling seed value
          as.integer(control$noGlobalPruning),
                                            # -g: "turn off the global tree pruning stage" var name: GLOBAL
          as.double(control$CF),            # -c: "set the Pruning CF value" var name: CF

          ## Also, for the number of minimum cases, I'm not sure what the
          ## default should be. The code looks like it dynamically sets the
          ## value (as opposed to a static, universal integer
          as.integer(control$minCases),     # -m : "set the Minimum cases" var name: MINITEMS

          as.logical(control$fuzzyThreshold),
                                            # -p "use the Fuzzy thresholds option" var name: PROBTHRESH     
          
          ## the model is returned in 2 files: .rules and .tree
          tree = character(1),             # pass back C5.0 tree as a string
          rules = character(1),            # pass back C5.0 rules as a string
          output = character(1),           # get output that normally goes to screen
          PACKAGE = "C50"
          )


  
  out <- list(data = dataString,
              names = namesString,
              cost = costString,
              caseWeights = !is.null(weights),
              control = control,
              trials = trials,
              costs = costs,
              dims = dim(x),
              call = funcCall)  

  class(out) <- "C5.0"
  out
}


C5.0Control <- function(subset = TRUE,    ## in C, equals  SUBSET=0,	/* subset tests allowed */
                        rules = FALSE,    ## in C, equals  RULES=0,	/* rule-based classifiers */
                        bands = 0,
                        winnow = FALSE,
                        noGlobalPruning = FALSE,
                        CF = 0.25,
                        minCases = 2,
                        fuzzyThreshold = FALSE,
                        sample = 0.0,
                        seed = sample.int(4096, size=1) - 1L,
                        label = "outcome")
  {
    if(CF < 0 | CF > 1)
      stop("confidence level must between 0 and 1")
    if(sample < 0.0 | sample > 99.9)
      stop("sampling percentage must be between 0.0 and 99.9")

    if(bands > 2 & !rules)
      {
        warning("rule banding only works with rules; 'rules' was changed to TRUE")
        rules <- TRUE
      }
    if(bands == 1 | bands > 10000)
      stop("if used, bands must be between 2 and 10000")
    
    list(subset = subset,
         rules = rules,
         bands = bands,
         winnow = winnow,
         noGlobalPruning = noGlobalPruning,
         CF = CF,
         minCases = minCases,
         fuzzyThreshold = fuzzyThreshold,
         sample = sample / 100,
         label = label,
         seed = seed %% 4096L)
  }


print.C5.0 <- function(x, ...)
  {
    cat("\nCall:\n", truncateText(deparse(x$call, width.cutoff = 500)), "\n\n", sep = "")

    cat("Number of samples:", x$dims[1],
        "\nNumber of predictors:", x$dims[2],
        "\n\n")

    if(x$trials > 1) cat("Number of boosting iterations:", x$trials, "\n\n")

    otherOptions <- NULL
    if(x$control$subset) otherOptions <- c(otherOptions, "attribute subsetting")   
    if(x$control$rules) otherOptions <- c(otherOptions, "rules")
    if(x$control$winnow) otherOptions <- c(otherOptions, "winnowing")
    if(! x$control$noGlobalPruning) otherOptions <- c(otherOptions, "global pruning")
    if(x$control$CF != 0.25) otherOptions <- c(otherOptions,
                                               paste("confidence level: ", x$control$CF, sep = ""))
    if(x$control$minCases != 2) otherOptions <- c(otherOptions,
                                                  paste("minimum number of cases: ", x$control$minCases, sep = ""))
    if(x$control$fuzzyThreshold) otherOptions <- c(otherOptions, "fuzzy thresholds")    
    if(x$control$bands > 0) otherOptions <- c(otherOptions,
                                              paste(x$control$bands, " utility bands", sep = ""))
    if(x$control$sample > 0) otherOptions <- c(otherOptions,
                                               paste(round(100*x$control$sample, 1), "% sub-sampling", sep = ""))
    if(!is.null(otherOptions))
      {
        cat(truncateText(paste("Other options:", paste(otherOptions, collapse = ", "))))
        cat("\n\n")
      }
    

    if(!is.null(x$cost))
      {
        cat("Cost Matrix:\n")
        print(x$cost)
      }    
    cat("\n")
  }


summary.C5.0 <- function(object, ...)
  {
    out <- list(output = object$output, call = object$call)
    class(out) <- "summary.C5.0"
    out
  }

print.summary.C5.0 <- function(x, ...)
  {
    cat("\nCall:\n", truncateText(deparse(x$call, width.cutoff = 500)), "\n\n", sep = "")
    cat(x$output)
    cat("\n")
    invisible(x) 
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


if(FALSE)
  {
    library(C5.0)

    test <- matrix(0, 3, 3)
    test[1, 1] <- 10
    test[1, 2] <- 1
    test[3, 2] <- 2
    mod <- C5.0(iris[, 1:4], iris$Species, costs = test)

    C5.0(iris[, 1:4], iris$Species, costs = test,
         trials = 100,
         control=C5.0Control(
           CF = .1, winnow = TRUE,
           globalPruning = TRUE, minCases = 10, rule = TRUE,
           sample = 10, bands = 10, fuzzyThreshold = TRUE))


  }
