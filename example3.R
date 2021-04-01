#!/usr/bin/env Rscript

## This is an example script to run dataframe_13f on Baupost's
## filings, run some conversions, and then output a CSV.

library(dplyr)
library(XML)
source("parse_13f.R")
options("width"=200)

## This XML file came from:
## https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001061768&type=13F&dateb=&owner=include&count=40
## If I wrote this right, any form13fInfoTable.xml should work.
xmlfile <- xmlParse("baupost-20210212-form13fInfoTable.xml")
root <- xmlRoot(xmlfile)

## Get raw data from 13F XML:
baupost_df <- dataframe_13f(root)

## Dump it to CSV & screen:
print("Raw data:")
print(baupost_df)
write.csv(baupost_df, file="baupost_20210212_raw.csv", row.names=FALSE)

## Get mapping of (some) CUSIPs to symbols into list 'cusip_sym', such
## that cusip_sym[["<cusip symbol>"]] is the ticker symbol:
cusip_sym <- c()
cusip_sym_df <- read.csv("./cusip_to_symbol.csv", stringsAsFactors=FALSE)
for (idx in 1:nrow(cusip_sym_df)) {
    cusip <- cusip_sym_df[idx, "cusip"]
    cusip_sym[cusip] <- cusip_sym_df[idx, "Symbol"]
}

cusip_descr <- c()
cusip_descr_df <- read.csv("./cusip_to_descr.csv", stringsAsFactors=FALSE)
for (idx in 1:nrow(cusip_descr_df)) {
    cusip <- cusip_descr_df[idx, "cusip"]
    cusip_descr[cusip] <- cusip_descr_df[idx, "Description"]
}

## Process it a bit with dplyr:
holdings <- baupost_df %>%
    ## Parse numbers:
    mutate(valueUSD = 1000 * as.numeric(value),
           shares = sshPrnamt,
           sharePrice = valueUSD / shares,
           Symbol = cusip_sym[cusip]
           ## Descr = cusip_descr[cusip],
           ) %>%
    ## Get 'Percent' as the percent of the total portfolio:
    mutate(percent = 100 * valueUSD / sum(valueUSD)) %>%
    ## Grab only certain columns:
    select(nameOfIssuer, cusip, valueUSD, percent, shares, sharePrice, Symbol) %>%
    ## And order by the percentage of the portfolio:
    arrange(desc(percent))

write.csv(holdings, file="baupost_20210212_holdings.csv", row.names=FALSE)
print("Processed data:")
print(holdings)

## This appears to get identical results to corresponding fields in
## https://whalewisdom.com/filer/baupost-group-llc-ma#/tabholdings_tab_link
## though I do not do anything with previous shares.

## Read portfolio CSV & discard last 3 lines (they're just a notice
## from the broker):
portfolio_csv <- "Portfolio_Positions_Mar-10-2021.csv"
portfolio_df <- read.csv(portfolio_csv, stringsAsFactors=FALSE) %>%
    slice(1:(n()-3)) %>%
    select(Symbol, Quantity, Last.Price, Cost.Basis)
## Cost.Basis was formerly Cost.Basis.Total until Fidelity changed the
## CSV format.
## Also, run the CSV through: sed -i -e "s/,\s$//g"
## Not sure why, but also Quantity is no longer numeric:
portfolio_df$Quantity = as.numeric(portfolio_df$Quantity)

comp <- left_join(holdings, portfolio_df, c("Symbol")) %>%
    select(-valueUSD, -percent) %>%
    mutate(Quantity = ifelse(is.na(Quantity), 0, Quantity))

## 'anchor' is the index of which asset to judge changes by
anchor <- 2

comp <- comp %>%
    mutate(sharesRatio = shares / holdings[anchor, "shares"],
           sharesRatioPortfolio = Quantity / comp[anchor, "Quantity"],
           QuantityAdjust = sharesRatio * comp[anchor, "Quantity"] - Quantity) %>%
    select(-sharesRatio, -sharesRatioPortfolio, -sharePrice)

options(scipen = 50)
print(comp)

write.csv(comp, file=paste("portfolio_adjust.csv", sep=''),
          row.names=FALSE)

## QuantityAdjust in this dataframe is the change that should be made
## in the portfolio (+ = purchase shares, - = sell shares) in order to
## equalize the ratios of shares between the portfolio and the hedge
## fund.
