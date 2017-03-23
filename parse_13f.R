#!/usr/bin/env Rscript

library(XML)

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

## This returns a dataframe containing the information from an SEC 13F
## filing.  Supply the document's XML root in 'xml_root' (from
## form13fInfoTable.xml).
dataframe_13f <- function(xml_root) {
    info <- getNodeSet(root, "//*[local-name() = 'infoTable']")

    ## Turn the raw data into a dataframe:
    infotable <- data.frame(
        nameOfIssuer          = vapply(info, txt("nameOfIssuer"), c("")),
        titleOfClass          = vapply(info, txt("titleOfClass"), c("")),
        cusip                 = vapply(info, txt("cusip"), c("")),
        value                 = as.numeric(vapply(info, txt("value"), c(""))),
        sshPrnamt             = as.numeric(vapply(info, txt("sshPrnamt", "shrsOrPrnAmt"), c(""))),
        sshPrnamtType         = vapply(info, txt("sshPrnamtType", "shrsOrPrnAmt"), c("")),
        votingAuthoritySole   = as.numeric(vapply(info, txt("Sole", "votingAuthority"), c(""))),
        votingAuthorityShared = as.numeric(vapply(info, txt("Shared", "votingAuthority"), c(""))),
        votingAuthorityNone   = as.numeric(vapply(info, txt("None", "votingAuthority"), c(""))),
        investmentDiscretion  = vapply(info, txt("investmentDiscretion"), c(""))
    )
}
