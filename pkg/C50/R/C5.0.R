C5.0 <-  function(x, ...) UseMethod("C5.0")

C5.0.default <- function(x, y,
                         trials = 0,
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
      if(ncol(costs) != nClass || nrow(costs) != nClass)
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

  if(!is.data.frame(x) & !is.matrix(x)) stop("x must be a matrix or data frame")

  if(!is.null(weights) && !is.numeric(weights))
    stop("case weights must be numeric")
  
  ## TODO: add case weights to these files when needed
  namesString <- makeNamesFile(x, y, label = control$label, comments = TRUE)
  dataString <- makeDataFile(x, y)

  tcl("file" ,"mkdir" ,"cfive://cfive")

  if(any(nchar(namesString))) {
    namesfile <- tcl("open" ,"cfive://cfive/cfive.names" ,"w")
    tcl("puts" ,namesfile ,namesString)
    tcl("close" ,namesfile)
  }

  if (any(nchar(dataString))) {
    datafile <- tcl("open" ,"cfive://cfive/cfive.data" ,"w")
    tcl("puts" ,datafile ,dataString)
    tcl("close" ,datafile)
  }

  if (any(nchar(costString))) {
    costfile <- tcl("open" ,"cfive://cfive/cfive.costs" ,"w")
    tcl("puts" ,costfile ,costString)
    tcl("close" ,costfile)
  }

  #because of limitations of the current tcl package used for in-memory files,
  #this directory change should happen *after* at least one file is created
  #in the directory
  tcl("cd" ,"cfive://cfive")

  cfiveopts <- c("-f" ,"cfive")

  outtype <- "tree"
  if (control$rules) {
    cfiveopts <- c(cfiveopts ,"-r")
    outtype <- "rules"
  }
  if (control$subset) {
    cfiveopts <- c(cfiveopts ,"-s")
  }

  if (control$bands) {
    cfiveopts <- c(cfiveopts ,"-u" ,control$bands)
  }

  if (trials) {
    cfiveopts <- c(cfiveopts ,"-t" ,trials)
  }

  if (control$winnow) {
    cfiveopts <- c(cfiveopts ,"-w")
  }

  if (control$sample) {
    cfiveopts <- c(cfiveopts ,"-S" ,control$sample)
  }

  if (control$seed) {
    cfiveopts <- c(cfiveopts ,"-I" ,control$seed)
  }

  if (control$noGlobalPruning) {
    cfiveopts <- c(cfiveopts ,"-g")
  }

  if (control$CF) {
    cfiveopts <- c(cfiveopts ,"-c" ,control$CF)
  }

  if (control$minCases) {
    cfiveopts <- c(cfiveopts ,"-c" ,control$minCases)
  }

  if (control$fuzzyThreshold) {
    cfiveopts <- c(cfiveopts ,"-p")
  }

  cfiveopts <- as.list(cfiveopts)
  Z <- tclArray()
  cfivecmd <- c("Rcfive" ,list(Z) ,cfiveopts)
  do.call("tcl" ,cfivecmd) 

  out <- list(data = dataString
              ,names = namesString
              ,cost = costString
              ,caseWeights = !is.null(weights)
              ,control = control
              ,trials = trials
              ,costs = costs
              ,dims = dim(x)
              ,call = funcCall
              ,options = cfiveopts 
              ,outtype = outtype
              ,stdout = tclvalue(Z$stdout)
              ,stderr = tclvalue(Z$stderr)
              ,tree = tclvalue(Z$tree)
              ,rules = tclvalue(Z$rules)
              ,out = tclvalue(Z$out)
              ,set = tclvalue(Z$set)
              )  

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
         #sample = sample / 100,
         sample = sample,
         label = label,
         seed = seed %% 4096L)
  }


print.C5.0 <- function(x, ...)
  {
    cat("\nCall:\n", truncateText(deparse(x$call, width.cutoff = 500)), "\n\n", sep = "")

    cat(
        "Number of samples:" ,x$dims[1]
        ,"\nNumber of predictors:" ,x$dims[2]
        ,"\ncfive options:" ,as.character(x$options)
        ,"\nouttype: " ,x$outtype
        ,"\nstdout:\n" ,x$stdout
        ,"\nstderr:\n" ,x$stderr
        ,"\ntree:\n" ,x$tree
        ,"\nrules:\n" ,x$rules
        ,"\nout:\n" ,x$out
        ,"\nset:\n" ,x$set
        ,"\n\n"
        )

    if(x$trials > 1) cat("Number of boosting iterations:", x$trials, "\n\n")

    otherOptions <- NULL
    if(x$control$subset) otherOptions <- c(otherOptions, "attribute subsetting")   
    if(x$control$rules) otherOptions <- c(otherOptions, "rules")
    if(x$control$winnow) otherOptions <- c(otherOptions, "winnowing")
    if(!(x$control$noGlobalPruning)) otherOptions <- c(otherOptions, "global pruning")
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
           noGlobalPruning = FALSE, minCases = 10, rule = TRUE,
           sample = 10, bands = 10, fuzzyThreshold = TRUE))


  }

