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
xmlfile <- xmlParse("baupost-20170214-form13fInfoTable.xml")
root <- xmlRoot(xmlfile)

## Get raw data from 13F XML:
baupost_df <- dataframe_13f(root)

## Dump it to CSV & screen:
print("Raw data:")
print(baupost_df)
write.csv(baupost_df, file="baupost_20170214_raw.csv", row.names=FALSE)

## Process it a bit with dplyr, and write back out:
holdings <- baupost_df %>%
    ## Parse numbers:
    mutate(valueUSD = 1000 * as.numeric(value),
           shares = sshPrnamt,
           sharePrice = valueUSD / shares) %>%
    ## Get 'Percent' as the percent of the total portfolio:
    mutate(percent = 100 * valueUSD / sum(valueUSD)) %>%
    ## Grab only certain columns:
    select(nameOfIssuer, cusip, valueUSD, percent, shares, sharePrice) %>%
    ## And order by the percentage of the portfolio:
    arrange(desc(percent))

write.csv(holdings, file="baupost_20170214_holdings.csv", row.names=FALSE)
print("Processed data:")
print(holdings)

## This appears to get identical results to corresponding fields in
## https://whalewisdom.com/filer/baupost-group-llc-ma#/tabholdings_tab_link
## though I do not do anything with previous shares.
