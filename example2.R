#!/usr/bin/env Rscript

## This runs dataframe_13f on two of Baupost's filings (adjacent
## ones), runs some conversions, determines the change in the
## portfolio between the two filings, and outputs a CSV with this
## information.

library(dplyr)
library(XML)
source("parse_13f.R")
options("width"=200)

get_13f_holdings <- function(fname) {
    xmlfile <- xmlParse(fname)
    root <- xmlRoot(xmlfile)

    ## Get raw data from 13F XML, process it a bit with dplyr, and
    ## write back out:
    df <- dataframe_13f(root) %>%
        ## Parse numbers:
        mutate(valueUSD = 1000 * as.numeric(value),
               shares = sshPrnamt,
               sharePrice = valueUSD / shares) %>%
        ## Get 'Percent' as the percent of the total portfolio:
        mutate(percent = 100 * valueUSD / sum(valueUSD)) %>%
        ## Grab only certain columns:
        select(nameOfIssuer, cusip, valueUSD, percent, shares, sharePrice)
    return(df)
}

date1 <- c("20170512")
date2 <- c("20170811")
df1 <- get_13f_holdings(paste("baupost-", date1, "-form13fInfoTable.xml", sep=""))
df2 <- get_13f_holdings(paste("baupost-", date2, "-form13fInfoTable.xml", sep=""))

delta <- full_join(df1, df2, c("nameOfIssuer", "cusip"))
delta[is.na(delta)] <- 0

delta <- delta %>%
    mutate(valueChange = valueUSD.y - valueUSD.x,
           sharesChange = shares.y - shares.x,
           transEst = sharesChange * (sharePrice.y + sharePrice.x) / 2,
           note =
               ifelse(
                   shares.y == 0,
                   "Sold all",
                   ifelse(
                       shares.x > 0,
                       ifelse(
                          sharesChange == 0,
                          "",
                          ifelse(sharesChange > 0,
                              "Bought more",
                              "Sold some")),
                       "Bought new"))) %>%
    select(nameOfIssuer, cusip, valueUSD = valueUSD.y, percent = percent.y,
           shares = shares.y, sharePrice = sharePrice.y, valueChange,
           sharesChange, transEst, note) %>%
    arrange(desc(percent))

write.csv(delta, file=paste("baupost_", date2, "_changes.csv", sep=''),
          row.names=FALSE)
print("Processed data:")
print(delta)

value2 <- summarise(df2, valueUSD = sum(valueUSD))$valueUSD
value1 <- summarise(df1, valueUSD = sum(valueUSD))$valueUSD
valDelta <- value2 - value1
print(sprintf("Total change in fund value (USD): $%s (%+.2f%%)",
              prettyNum(valDelta, big.mark=",", scientific=FALSE),
              100 * (valDelta / value1)))

trans <- summarise(delta, transEst = sum(transEst))$transEst
print(sprintf("Estimated net transactions: $%s",
              prettyNum(trans, big.mark=",", scientific=FALSE)))

pos <- delta %>%
    filter(transEst > 0) %>%
    summarise(transEst = sum(transEst))
neg <- delta %>%
    filter(transEst < 0) %>%
    summarise(transEst = sum(transEst))
print(sprintf("   Estimated bought: $%s",
              prettyNum(pos$transEst, big.mark=",", scientific=FALSE)))
print(sprintf("   Estimated sold: $%s",
              prettyNum(-neg$transEst, big.mark=",", scientific=FALSE)))
