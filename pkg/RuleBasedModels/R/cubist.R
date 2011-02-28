cubist <-  function(x, ...) UseMethod("cubist")

cubistControl <- function(unbiased = FALSE,
                          composite = "auto",
                          neighbors = 3,
                          committees = 1,
                          rules = NA,
                          extrapolation = 100,
                          sample = 99.9,
                          seed = 1,
                          label = "outcome")
  {
    if(!is.na(rules) & (rules < 1 | rules > 1000000))
      stop("number of rules must be between 1 and 1000000")
    if(extrapolation <= 0 | extrapolation > 100)
      stop("percent extrapolation must be greater than 0 and less than or equal to 100")
    if(neighbors < 1 | neighbors > 9)
      stop("number of neighbors must be between 1 and 9")
    if(sample < .01 | sample > 99.9)
      stop("sampling percentage must be between 0.01 and 99.9")     
    if(committees < 1 | committees > 100)
      stop("number of committees must be between 1 and 100")     
    
    list(unbiased = unbiased,
         composite = composite,
         neighbors = neighbors,
         committees = committees,
         rules = rules,
         extrapolation = extrapolation,
         sample = sample,
         label = label,
         seed = seed)    
  }

cubist.default <- function(x, y, control = cubistControl(), ...)
{
  funcCall <- match.call(expand.dots = TRUE)
  if(!is.numeric(y)) stop("cubist models require a numeric outcome")

  ## TODO: check for missing outcome data
  
  namesString <- makeNamesFile(x, y, label = control$label, comments = TRUE)
  dataString <- makeDataFile(x, y)

  ## TODO: figure out how to combine the combinations of -i and -a

  if(FALSE)
    {
      Z <- .C("cubist",
              as.character(namesString), 
              as.character(dataString),
              as.integer(control$unbiased),     # -u : generate unbiased rules
              as.integer(control$composite),    # -i and -a : how to combine these?
              as.integer(control$neighbors),    # -n : et the number of nearest neighbors (1 to 9)
              as.integer(control$committees),   # -c : construct a committee model
              as.double(control$sample),        # -S : use a sample of x% for training and a disjoint sample for testing
              as.integer(control$sample),       # -S : use a sample of x% for training and a disjoint sample for testing
              as.integer(control$seed),         # -I : set the sampling seed value 
              as.integer(control$rules),        # -r: set the maximum number of rules
              as.double(control$extrapolation), # -e : set the extrapolation limit
              as.character("")                  # pass back the contents of name.model as a string
              )
    }
  cat(namesString)

}

if(FALSE)
  {
    ## testing example

    cubist(iris[,-1], iris[,1])
  }
