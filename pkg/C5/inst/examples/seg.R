library(C50)

set.seed(17)
moo <- matrix(rnorm(5000), nrow=100)
moo1 <- cbind(sample(1:6, 100, replace=T), moo)
colnames(moo1) <- c("result", paste("A", 1:50, sep=""))
stats <- data.frame(moo1)
stats.nl <- stats[, -c(13:25,10,26:28,3)]

cat('First loop:\n')
for (d in 1:nrow(stats.nl)) {
    print(d)
    stats.nl.g <- stats.nl[-d,]
    stats.nl.g$result <- factor(ifelse(stats.nl.g$result <= 1, "yes", "no"))
    la <- C5.0(result~., stats.nl.g)
}

cat('Second loop:\n')
for (d in 1:nrow(stats)) {
    print(d)
    stats.g <- stats[-d,]
    stats.g$result <- factor(ifelse(stats.g$result <= 1, "yes", "no"))
    la <- C5.0(result~., stats.g)
}
