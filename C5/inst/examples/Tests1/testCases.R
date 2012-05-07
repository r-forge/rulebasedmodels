library(C50)

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

## ./c5.0 -f churnTestCase -r -I 1 > SimpleRule.txt
## ./c5.0 -f churnTestCase  -I 1 > SimpleTree.txt
## ./c5.0 -f churnTestCase -r -I 1 -w > WinnowRule.txt
## ./c5.0 -f churnTestCase  -I 1 -w > WinnowTree.txt

trimOutput <- function(x)
  {
    x <- strsplit(x, "\n")[[1]]
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

SimpleRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE))


SimpleTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1))


WinnowRuleR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, rules = TRUE, winnow = TRUE))


WinnowTreeR <- C5.0(churnTrain[,-ncol(churnTrain)], churnTrain$churn,
                    control = C5.0Control(seed = 1, winnow = TRUE))


WinnowTreeExpected <- getTestCase("~/Code/C50clean/WinnowTree.txt")
all.equal(WinnowTreeExpected, trimOutput(WinnowTreeR$output))

WinnowRuleExpected <- getTestCase("~/Code/C50clean/WinnowRule.txt")
all.equal(WinnowRuleExpected, trimOutput(WinnowRuleR$output))


SimpleTreeExpected <- getTestCase("~/Code/C50clean/SimpleTree.txt")
all.equal(SimpleTreeExpected, trimOutput(SimpleTreeR$output))

SimpleRuleExpected <- getTestCase("~/Code/C50clean/SimpleRule.txt")
all.equal(SimpleRuleExpected, trimOutput(SimpleRuleR$output))


