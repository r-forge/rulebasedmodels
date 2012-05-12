library(C50)
data(churn)

if(FALSE)
  {

    churnNames <- C50:::makeNamesFile(churnTrain[,-ncol(churnTrain)],
                                      churnTrain$churn,
                                      label = "churn")
    cat(churnNames[2], file = "~/tmp/churnTestCase.names")

    churnData <- C50:::makeDataFile(churnTrain[,-ncol(churnTrain)],
                                    churnTrain$churn)
    cat(churnData, file = "~/tmp/churnTestCase.data")
  }

## ./c5.0 -f churnTestCase -r -I 1            > SimpleRule.txt
SimpleRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -s         > SubsetRule.txt
SubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, subset = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w         > WinnowRule.txt
WinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, winnow = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w -s      > WinnowSubsetRule.txt
WinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(seed = 1, rules = TRUE, winnow = TRUE, subset = TRUE))

## ./c5.0 -f churnTestCase -r -I 1       -u 3 > BandedRule.txt
BandedRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(
                      seed = 1, rules = TRUE,
                      bands = 3))

## ./c5.0 -f churnTestCase -r -I 1 -s    -u 3 > BandedSubsetRule.txt
BandedSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(
                            seed = 1, rules = TRUE,
                            subset = TRUE,
                            bands = 3))

## ./c5.0 -f churnTestCase -r -I 1 -w    -u 3 > BandedWinnowRule.txt
BandedWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(
                            seed = 1, rules = TRUE,
                            winnow = TRUE,
                            bands = 3))

## ./c5.0 -f churnTestCase -r -I 1 -w -s -u 3 > BandedWinnowSubsetRule.txt
BandedWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                                control = C5.0Control(
                                  seed = 1, rules = TRUE,
                                  winnow = TRUE, subset = TRUE,
                                  bands = 3))

## ./c5.0 -f churnTestCase -r -I 1            -c 75 > CfRule.txt
CfRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                control = C5.0Control(
                  seed = 1, rules = TRUE,
                  CF = .75))
## ./c5.0 -f churnTestCase -r -I 1 -s         -c 75 > CfSubsetRule.txt
CfSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        subset = TRUE,
                        CF = .75))

## ./c5.0 -f churnTestCase -r -I 1 -w         -c 75 > CfWinnowRule.txt
CfWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        winnow = TRUE, 
                        CF = .75))

## ./c5.0 -f churnTestCase -r -I 1 -w -s      -c 75 > CfWinnowSubsetRule.txt
CfWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              winnow = TRUE, subset = TRUE,
                              CF = .75))

## ./c5.0 -f churnTestCase -r -I 1       -u 3 -c 75 > CfBandedRule.txt
CfBandedRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        CF = .75,
                        bands = 3))
## ./c5.0 -f churnTestCase -r -I 1 -s    -u 3 -c 75 > CfBandedSubsetRule.txt
CfBandedSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              subset = TRUE,
                              CF = .75,
                              bands = 3))

## ./c5.0 -f churnTestCase -r -I 1 -w    -u 3 -c 75 > CfBandedWinnowRule.txt
CfBandedWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              winnow = TRUE, 
                              CF = .75,
                              bands = 3))
## ./c5.0 -f churnTestCase -r -I 1 -w -s -u 3 -c 75 > CfBandedWinnowSubsetRule.txt
CfBandedWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                                  control = C5.0Control(
                                    seed = 1, rules = TRUE,
                                    winnow = TRUE, subset = TRUE,
                                    CF = .75,
                                    bands = 3))


## ./c5.0 -f churnTestCase -I 1              > SimpleTree.txt
SimpleTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1))

## ./c5.0 -f churnTestCase -I 1 -w           > WinnowTree.txt
WinnowTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, winnow = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w -s        > WinnowSubsetTree.txt
WinnowSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(seed = 1,
                            winnow = TRUE,
                            subset = TRUE))


## ./c5.0 -f churnTestCase -I 1    -s        > SubsetTree.txt
SubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1,
                      subset = TRUE))

## ./c5.0 -f churnTestCase -I 1       -c 75 > CfTree.txt
CfTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                control = C5.0Control(seed = 1,
                  CF = .75))

## ./c5.0 -f churnTestCase -I 1 -w    -c 75 > CfWinnowTree.txt
CfWinnowTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(seed = 1,
                        CF = .75,
                        winnow = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w -s -c 75 > CfWinnowSubsetTree.txt
CfWinnowSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(seed = 1,
                              CF = .75,
                              winnow = TRUE,
                              subset = TRUE))

## ./c5.0 -f churnTestCase -I 1    -s -c 75 > CfSubsetTree.txt
CfSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(seed = 1,
                        CF = .75,
                        subset = TRUE))

## ./c5.0 -f churnTestCase -r -I 1            -g > GlobalRule.txt
GlobalRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -s         -g > GlobalSubsetRule.txt
GlobalSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, subset = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w         -g > GlobalWinnowRule.txt
GlobalWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, winnow = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w -s      -g > GlobalWinnowSubsetRule.txt
GlobalWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(seed = 1, rules = TRUE, winnow = TRUE, subset = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1       -u 3 -g > GlobalBandedRule.txt
GlobalBandedRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(
                      seed = 1, rules = TRUE,
                      bands = 3, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -s    -u 3 -g > GlobalBandedSubsetRule.txt
GlobalBandedSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(
                            seed = 1, rules = TRUE,
                            subset = TRUE,
                            bands = 3, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w    -u 3 -g > GlobalBandedWinnowRule.txt
GlobalBandedWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(
                            seed = 1, rules = TRUE,
                            winnow = TRUE,
                            bands = 3, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w -s -u 3 -g > GlobalBandedWinnowSubsetRule.txt
GlobalBandedWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                                control = C5.0Control(
                                  seed = 1, rules = TRUE,
                                  winnow = TRUE, subset = TRUE,
                                  bands = 3, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1            -c 75 -g > GlobalCfRule.txt
GlobalCfRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                control = C5.0Control(
                  seed = 1, rules = TRUE,
                  CF = .75,
                  noGlobalPruning = TRUE))
## ./c5.0 -f churnTestCase -r -I 1 -s         -c 75 -g > GlobalCfSubsetRule.txt
GlobalCfSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        subset = TRUE,
                        CF = .75, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w         -c 75 -g > GlobalCfWinnowRule.txt
GlobalCfWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        winnow = TRUE, 
                        CF = .75, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w -s      -c 75 -g > GlobalCfWinnowSubsetRule.txt
GlobalCfWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              winnow = TRUE, subset = TRUE,
                              CF = .75, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1       -u 3 -c 75 -g > GlobalCfBandedRule.txt
GlobalCfBandedRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(
                        seed = 1, rules = TRUE,
                        CF = .75,
                        bands = 3, noGlobalPruning = TRUE))
## ./c5.0 -f churnTestCase -r -I 1 -s    -u 3 -c 75 -g > GlobalCfBandedSubsetRule.txt
GlobalCfBandedSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              subset = TRUE,
                              CF = .75,
                              bands = 3, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -r -I 1 -w    -u 3 -c 75 -g > GlobalCfBandedWinnowRule.txt
GlobalCfBandedWinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(
                              seed = 1, rules = TRUE,
                              winnow = TRUE, 
                              CF = .75,
                              bands = 3, noGlobalPruning = TRUE))
## ./c5.0 -f churnTestCase -r -I 1 -w -s -u 3 -c 75 -g > GlobalCfBandedWinnowSubsetRule.txt
GlobalCfBandedWinnowSubsetRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                                  control = C5.0Control(
                                    seed = 1, rules = TRUE,
                                    winnow = TRUE, subset = TRUE,
                                    CF = .75,
                                    bands = 3, noGlobalPruning = TRUE))


## ./c5.0 -f churnTestCase -I 1              -g > GlobalTree.txt
GlobalTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w           -g > GlobalWinnowTree.txt
GlobalWinnowTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, winnow = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w -s        -g > GlobalWinnowSubsetTree.txt
GlobalWinnowSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                          control = C5.0Control(seed = 1,
                            winnow = TRUE,
                            subset = TRUE, noGlobalPruning = TRUE))


## ./c5.0 -f churnTestCase -I 1    -s        -g > GlobalSubsetTree.txt
GlobalSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1,
                      subset = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1       -c 75 -g > GlobalCfTree.txt
GlobalCfTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                control = C5.0Control(seed = 1,
                  CF = .75, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w    -c 75 -g > GlobalCfWinnowTree.txt
GlobalCfWinnowTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(seed = 1,
                        CF = .75,
                        winnow = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1 -w -s -c 75 -g > GlobalCfWinnowSubsetTree.txt
GlobalCfWinnowSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                            control = C5.0Control(seed = 1,
                              CF = .75,
                              winnow = TRUE,
                              subset = TRUE, noGlobalPruning = TRUE))

## ./c5.0 -f churnTestCase -I 1    -s -c 75 -g > GlobalCfSubsetTree.txt
GlobalCfSubsetTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                      control = C5.0Control(seed = 1,
                        CF = .75,
                        subset = TRUE, noGlobalPruning = TRUE))



trimOutput <- function(x, split = TRUE)
  {
    if(split) x <- strsplit(x, "\n")[[1]]
    bottomIndex <- grep("^Read", x)
    x <- x[-(1:bottomIndex)]    
    topIndex <- grep("^\tAttribute usage", x)
    x <- x[-((topIndex+1):length(x))]        
    x
  }

getTestCase <- function(file, trim = TRUE)
  {
    raw <- read.table(file, sep = "\n", stringsAsFactors = FALSE,
                      blank.lines.skip = FALSE)[,1]
    raw <- paste(raw, collapse = "\n")
    if(trim) raw <- trimOutput(raw)
    raw

  }

data(churn)

testCaseList <- grep("(Tree)|(Rule)", list.files(pattern = ".txt"), value = TRUE)

for(i in seq(along = testCaseList))
  {
    prefix <- testCaseList[i]
    expected <- getTestCase(prefix)
    obs <- trimOutput(get(gsub(".txt", "R", testCaseList[i], fixed = TRUE))$output)

    cat("Testing", testCaseList[i], "\n") 
    results <- all.equal(expected, obs)
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
            tmp <- cbind(expected, obs)
            colnames(tmp) <- c("expected", "observed")
            print(tmp)
            cat("\n")
          }

      }
    if(is.logical(results) && results) cat("passed!")
    cat("\n\n")

    rm(obs, expected, prefix, results)

  }





