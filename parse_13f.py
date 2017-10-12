#!/usr/bin/env python

# nix-shell -p python35Packages.pandas --command "python -i"

import xml.etree.ElementTree as ET
import pandas
import csv

def xml_to_dataframe(elements, attr_dict, prefix = ""):
    """Turn a list of elements into a Pandas DataFrame according to the
    attributes and conversions specified in 'attr_dict', which is a
    dictionary whose keys are the intended column name in that
    DataFrame and whose values are tuples containing (conversion
    function, XML path).  Conversion function is applied to the text
    at that XML path, and the XML path will have {0} replaced with
    optional 'prefix'.
    """
    def get_row(el):
        row = {}
        for k in attribs:
            fn, attr = attribs[k]
            row[k] = fn(el.find(attr.format(prefix)).text)
        return row
    # A row of dictionaries can be handled directly by Pandas:
    rows = [get_row(e) for e in elements]
    return pandas.DataFrame(rows)

# The dictionary of attributes from the XML file that we're interested
# in, and what types they should be.  (Specifically: key = desired
# column name, value = (conversion function, attribute).)
attribs = {
    "nameOfIssuer":           (str, "{0}nameOfIssuer"),
    "titleOfClass":           (str, "{0}titleOfClass"),
    "cusip":                  (str, "{0}cusip"),
    "value":                  (int, "{0}value"),
    "sshPrnamt":              (int, "{0}shrsOrPrnAmt/{0}sshPrnamt"),
    "sshPrnamtType":          (str, "{0}shrsOrPrnAmt/{0}sshPrnamtType"),
    "votingAuthoritySole":    (int, "{0}votingAuthority/{0}Sole"),
    "votingAuthorityShared":  (int, "{0}votingAuthority/{0}Shared"),
    "votingAuthorityNone":    (int, "{0}votingAuthority/{0}None"),
    "investmentDiscretion":   (str, "{0}investmentDiscretion"),
}

# Parse from an example XML file:
tree = ET.parse("baupost-20170811-form13fInfoTable.xml")
root = tree.getroot()

url_prefix = "{http://www.sec.gov/edgar/document/thirteenf/informationtable}"
df = xml_to_dataframe(
    root.findall("{0}infoTable".format(url_prefix)),
    attribs,
    url_prefix)

# Get table of (some) CUSIP IDs to ticker symbols.
cusip_to_symbol = pandas.read_csv("./cusip_to_symbol.csv")
# Note left join; we don't want to lose entries just because no symbol
# is available.
df = df.merge(cusip_to_symbol, how="left", on="cusip").fillna("")

# Dump to CSV and to screen:
df.to_csv("baupost_20170811_13f.csv", index=False)
pandas.set_option("display.width", None)
print(df)
