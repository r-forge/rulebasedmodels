## TODO:
## 3) R function to write R prediciton function


printCubistRules <- function(x, dig = max(3, getOption("digits") - 5))
  {
    comNum <- ruleNum <- condNum <- rep(NA, length(x))
    comIdx <- rIdx <- 0
    for(i in seq(along = x))
      {
        tt <- parser(x[i])
        if(names(tt)[1] == "rules")
          {
            comIdx <- comIdx + 1
            rIdx <- 0
          }
        comNum[i] <-comIdx
        if(names(tt)[1] == "conds")
          {
            rIdx <- rIdx + 1
            cIdx <- 0
          }
        ruleNum[i] <-rIdx
        if(names(tt)[1] == "type")
          {
            cIdx <- cIdx + 1
            condNum[i] <- cIdx
          }
      }
    
    numCom <- sum(grepl("^rules=", x))
    rulesPerCom <- unlist(lapply(split(ruleNum, as.factor(comNum)), max))
    rulesPerCom <- rulesPerCom[rulesPerCom > 0]
    names(rulesPerCom) <- paste("Com", 1:numCom)
    cat("Number of committees:", numCom, "\n")
    cat("Number of rules per committees:",
        paste(rulesPerCom, collapse = ", "), "\n\n")
   
    isNewRule <- ifelse(grepl("^conds=", x), TRUE, FALSE)
    isEqn <- ifelse(grepl("^coeff=", x), TRUE, FALSE) 
    
    cond <- rep("", length(x))
    isType2 <- grepl("^type=2", x)
    if(any(isType2)) cond[isType2] <- type2(x[isType2], dig = dig)$text
    isType3 <- grepl("^type=3", x)
    if(any(isType3)) cond[isType3] <- type3(x[isType3])$text

    isEqn <- grepl("^coeff=", x)
    eqtn <- rep("", length(x))
    eqtn[isEqn] <- eqn(x[isEqn], dig = dig)

    tmp <- x[isNewRule]
    tmp <- parser(tmp)
    ruleN <- rep(NA, length(x))
    ruleN[isNewRule] <- as.numeric(unlist(lapply(tmp, function(x) x["cover"])))
    
    for(i in seq(along = x))
      {
        if(isNewRule[i])
          {
            cat("Rule ", comNum[i], "/", ruleNum[i], ": (n=",
                ruleN[i], ")\n", sep = "")
            cat("  If\n")
          } else {
            if(cond[i] != "")
              {
                cat("  |", cond[i], "\n")
                if(cond[i+1] == "")
                  {
                    cat("  Then\n")
                    cat("    prediction =", eqtn[i+1], "\n\n")
                  }
              }
          }
      }
  }

type3 <- function(x)
  {
    aInd <- regexpr("att=", x)
    eInd <- regexpr("elts=", x)
    var <- substring(x, aInd + 4, eInd - 2)
    val <- substring(x, eInd + 5)
    multVals <- grepl(",", val)
    val <- gsub(",", ", ", val) 
    val <- ifelse(multVals, paste("{", val, "}", sep = ""), val)
    txt <- ifelse(multVals,  paste(var, "in", val),  paste(var, "=", val))
 
    list(var = var, val = val, text = txt)
  }

type2 <- function(x, dig = 3)
  {
    aInd <- regexpr("att=", x)
    cInd <- regexpr("cut=", x)
    rInd <- regexpr("result=", x)
    vInd <- regexpr("val=", x)

    var <- val <- rslt <- rep("", length(x))
    
    missingRule <- cInd < 1 & vInd > 0
    
    if(any(missingRule))
      {
        var[missingRule] <- substring(x[missingRule], aInd[missingRule] + 4, vInd[missingRule] - 2)
        val[missingRule] <- "NA"
        rslt[missingRule] <- "="  
      }
    if(any(!missingRule))
      {
        var[!missingRule] <- substring(x[!missingRule], aInd[!missingRule] + 4, cInd[!missingRule] - 2)        
        val[!missingRule] <- substring(x[!missingRule], cInd[!missingRule] + 4, rInd[!missingRule] - 1)
        val[!missingRule] <- format(as.numeric(val[!missingRule]), digits = dig)
        rslt[!missingRule] <- substring(x[!missingRule], rInd[!missingRule] + 7)
      }

    list(var = var, val = val, rslt = rslt,
         text = paste(var, rslt, val))
  }

eqn <- function(x, dig)
  {
    out <- rep("", length(x))

    for(j in seq(along = x))
      {
        starts <- gregexpr("(coeff=)|(att=)", x[j])[[1]]
        p <- (length(starts) - 1)/2
        vars <- vector(mode = "numeric", length = p + 1)
        tmp <- vector(mode = "character", length = length(starts))
        
        for(i in seq(along = starts))
          {
            if(i < length(starts))
              {
                txt <- substring(x[j], starts[i], starts[i + 1] - 2)
                
              } else txt <- substring(x[j], starts[i])
            tmp[i] <- gsub("(coeff=)|(att=)", "", txt)
          }

        valSeq <- seq(1, length(tmp), by = 2)
        vals <- as.double(tmp[valSeq])
        signs <- sign(vals)
        vals <- abs(vals)

        nms <- tmp[-valSeq]

        for(i in seq(along = vals))
          {
            if(i == 1)
              {
                txt <- ifelse(signs[1] == -1,
                              format(-vals[1], digits = dig),
                              format(vals[1], digits = dig))
              } else {
                tmp2 <- ifelse(signs[i] == -1,
                               paste("-", format(vals[i], digits = dig)),
                               paste("+", format(vals[i], digits = dig)))
                txt <- paste(txt, tmp2, nms[i-1])
              }
          }        
        out[j] <- txt
        
      }
    out
  }


parser <- function(x)
  {
    x <- strsplit(x, " ")
    x <- lapply(x,
                function(y)
                {
                  y <- strsplit(y, "=")
                  nms <- unlist(lapply(y, function(z) z[1]))
                  val <- unlist(lapply(y, function(z) z[2]))
                  names(val) <- nms
                  val
                })
    if(length(x) == 1) x <- x[[1]]
    x
  }



if(FALSE)
  {
    setwd("~/Downloads/Cubist")
    comMod <- read.delim("committee_example.model", stringsAsFactors = FALSE)[,1]
    printCubistRules(comMod, 1)
  }
