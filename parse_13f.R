#!/usr/bin/env Rscript

library(dplyr)
library(XML)

## This XML file came from:
## https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001061768&type=13F&dateb=&owner=include&count=40
## If I wrote this right, any form13fInfoTable.xml should work.
xmlfile <- xmlParse("baupost-20170214-form13fInfoTable.xml")
root <- xmlRoot(xmlfile)
info <- getNodeSet(root, "//*[local-name() = 'infoTable']")

## Kludgey function: Return a function which returns the text field from the
## node of the given name, or the node of the given name inside of the node
## named 'h'.
txt <- function(name, h=NA) {
  if (is.na(h)) {
    function(node) { xmlValue(node[name][[1]]) }
  } else {
    function(node) { xmlValue(node[h][[1]][name][[1]]) }
  }
}

## Turn the raw data into a dataframe:
infotable <- data.frame(
  nameOfIssuer = vapply(info, txt("nameOfIssuer"), c("")),
  titleOfClass = vapply(info, txt("titleOfClass"), c("")),
  cusip = vapply(info, txt("cusip"), c("")),
  value = as.numeric(vapply(info, txt("value"), c(""))),
  sshPrnamt = as.numeric(vapply(info, txt("sshPrnamt", "shrsOrPrnAmt"), c(""))),
  sshPrnamtType = vapply(info, txt("sshPrnamtType", "shrsOrPrnAmt"), c("")),
  votingAuthoritySole = as.numeric(vapply(info, txt("Sole", "votingAuthority"), c(""))),
  votingAuthorityShared = as.numeric(vapply(info, txt("Shared", "votingAuthority"), c(""))),
  votingAuthorityNone = as.numeric(vapply(info, txt("None", "votingAuthority"), c(""))),
  investmentDiscretion = vapply(info, txt("investmentDiscretion"), c(""))
  )

holdings <- infotable %>%
  ## Parse numbers:
  mutate(valueUSD = 1000 * as.numeric(value),
         shares = as.numeric(sshPrnamt),
         sharePrice = valueUSD / shares) %>%
  ## Get 'Percent' as the percent of the total portfolio:
  mutate(percent = 100 * valueUSD / sum(valueUSD)) %>%
  select(nameOfIssuer, cusip, valueUSD, percent, shares, sharePrice) %>%
  arrange(desc(percent))

## This appears to get identical results to corresponding fields in
## https://whalewisdom.com/filer/baupost-group-llc-ma#/tabholdings_tab_link
## though I do not do anything with previous shares.

## I'm also not sure what a good way is to turn the CUSIP into a
## ticker symbol. The FinancialInstrument library looks like it at
## least knows how to query online APIs for related information, but I
## wasn't able to get anywhere.
