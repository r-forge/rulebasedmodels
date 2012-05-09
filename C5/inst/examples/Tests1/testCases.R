
makeOptions <- function(x, base = ".")
  {
    opt <- rep("-I 1", nrow(x))
    opt <- ifelse(x$bands, paste(opt, "-u", x$bands), opt)
    opt <- ifelse(x$cf != .25, paste(opt, "-c", x$cf*100), opt)
    opt <- ifelse(x$winnow, paste(opt, "-w"), opt)
    opt <- ifelse(x$subset, paste(opt, "-s"), opt)
    opt <- ifelse(x$rules,  paste(opt, "-r"), opt)
    opt <- ifelse(x$fuzzy,  paste(opt, "-p"), opt)
    opt <- ifelse(x$noGlobal, paste(opt, "-g"), opt)
    opt <- ifelse(x$trials > 1, paste(opt, "-b -t", x$trials), opt)
    opt <- ifelse(x$sample > 0, paste(opt, "-S", x$sample*100), opt)    
    call <- paste(base, "/c5.0 -f churnTestCase ", opt, sep = "")
    call
  }

makeControl <- function(x)
  {
    C5.0Control(seed = 1, 
                winnow = x$winnow, subset = x$subset,
                rules = x$rules, fuzzyThreshold = x$fuzzy,
                noGlobalPruning = x$noGlobal,
                sample = x$sample,
                CF = x$cf, bands = x$bands)
  }


trimOutput <- function(x, split = TRUE)
  {
    if(split) x <- strsplit(x, "\n")[[1]]
    bottomIndex <- grep("^Read", x)
    x <- x[-(1:bottomIndex)]    
    topIndex <- grep("^\tAttribute usage", x)
    x <- x[-((topIndex+1):length(x))]        
    x
  }

makeHeader <- function(x, i = "")
  {
    cat("\nTest Case ", i, ": ", ifelse(x$rules, "rules, ", ""),
        ifelse(x$subset, "subsetting, ", ""),
        ifelse(x$winnow, "winnowing, ", ""),
        ifelse(x$fuzzyThreshold, "fuzzy thresholds, ", ""),
        ifelse(x$noGlobalPruning, "no global pruning, ", ""),
        ifelse(x$bands > 0, "bands, ", ""),
        ifelse(x$cf != 0.25, "CF 0.75, ", ""),
        ifelse(x$trials > 1, "boosting, ", ""),
        ifelse(x$sample > 0, "sampling, ", ""),        
        "\n", sep = "")
  }


library(C50)
data(churn)
setwd(system.file("examples", "Tests1", package = "C50"))
## path to command line version
c50Path <- "~/Code/C50clean"

combos <- expand.grid(bands = c(0, 3),
                      cf = c(.25, .75),
                      winnow = c(TRUE, FALSE),
                      subset = c(TRUE, FALSE),
                      rules = c(TRUE, FALSE),
                      fuzzy = c(TRUE, FALSE),
                      noGlobal = c(TRUE, FALSE),
                      trials = c(1, 12),
                      sample = c(0, .50))
                      
throwOut <- combos$bands & !combos$rules
combos <- combos[!throwOut,]

outputs <- vector(mode = "list", length = nrow(combos))


for(i in 1:nrow(combos))
  {
    makeHeader(combos[i,], i)
    cat("   ", makeOptions(combos[i,], c50Path), "\n")
    expected <- system(makeOptions(combos[i,], c50Path), intern = TRUE)
    fit <- C5.0(churnTrain[,-20], churnTrain$churn,
                trials = combos[i,"trials"],
                control = makeControl(combos[i,]))
    outputs[[i]] <- list(expected = expected, observed = strsplit(fit$output, "\n")[[1]])

    obs <- trimOutput(fit$output)
    expected <- trimOutput(expected, split = FALSE)
    
    results <- all.equal(obs, expected)

    if(!is.logical(results) || !results)
      {
        if(length(expected) == length(obs) && grepl("string mismatches", results))
          {
            cat("Differences:\n")
            tmp <- cbind(expected[expected != obs],
                         obs[expected != obs])
            colnames(tmp) <- c("expected", "observed")
            print(tmp)
            cat("\n")

          } else {
            cat("failed! - output different lengths")
            cat("\nExpected:\n")
            print(expected)
            cat("\nObserved:\n")
            print(obs)
            cat("\n")
          }

      }
    if(is.logical(results) && results) cat("passed!")
    cat("\n\n")

    rm(obs, expected, fit, results)

    cat("\n\n")


  }
