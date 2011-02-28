makeNamesFile <-
function(x, y, label = "outcome", comments = TRUE)
  {
    if(comments)
      {
        call <- match.call()
        out <- paste("| Generated using ", R.version.string, "\n",
                     "| on ", format(Sys.time(), "%a %b %d %H:%M:%S %Y"), "\n",
                     "| function call: ", paste(deparse(call)),
                     sep = "")
      } else out <- ""

    out <- paste(out,
                 "\n", label, ".\n",
                 "\n", label, ": continuous.",
                 sep = "")
    varData <- QuinlanAttributes(x)
    varData <- paste(names(varData), ": ", varData, sep = "", collapse = "\n")
    out <- paste(out, "\n", varData, sep = "")
    out


  }

