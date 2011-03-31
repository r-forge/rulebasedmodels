makeDataFile <-
function(x, y)
  {
    if(!is.data.frame(x)) x <- as.data.frame(x)
    x <- cbind(y, x)
    out <- capture.output(
                          write.table(x,
                                      sep = ",",
                                      na = "?",
                                      file = "",
                                      quote = FALSE,
                                      row.names = FALSE,
                                      col.names = FALSE))
    paste(paste(out, collapse = "\n"), "\n", sep="")
  }

