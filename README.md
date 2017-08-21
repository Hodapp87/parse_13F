# parse_13F
Some tools for parsing Form 13F filings with the SEC

Thus far, this is just an R script that I wrote to parse
[13F](https://en.wikipedia.org/wiki/Form_13F) filings.  These are
available as XML files from [EDGAR](https://www.sec.gov/edgar/searchedgar/companysearch.html).
For instance, if you want to [ride Seth Klarmann's coattails](http://www.forbes.com/2010/02/24/enzon-facet-nws-markets-intelligent-investing-seth-klarman.html),
those from [Baupost](https://en.wikipedia.org/wiki/Baupost_Group)
(CIK 0001061768) can be found [here](https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001061768&type=13F&dateb=&owner=include&count=40),
with the latest
[form13fInfoTable.xml](https://www.sec.gov/Archives/edgar/data/1061768/000114036117007238/form13fInfoTable.xml).

The R script `parse_13f.R` handles XML tables like the above.

`example.R` uses it to parse Baupost's 2017 Q1 filings
(also [here](./baupost-20170214-form13fInfoTable.xml)), dump the raw
data to a CSV (see [here](./baupost_20170214_raw.csv)), perform some
conversions with dplyr, order by percentage relative to the whole
portfolio, and then output a CSV file containing this new dataframe
(see [here](./baupost_20170214_holdings.csv)).

## To-do items

- It might be nice to turn the CUSIP into a ticker symbol in order to
  link the tables against other data sources - for instance, the
  present price. The
  [FinancialInstrument](https://cran.r-project.org/package=FinancialInstrument) library
  looks like it at least knows how to query online APIs for related
  information, but I wasn't able to get anywhere.
    - https://investor.vanguard.com/search/ will search, as will
      http://quotes.fidelity.com/ftgw/fbc/ofquotes/mmnet/SymLookup,
      but I don't know about a free API.
- I'd like to use the proper namespaces when finding nodes in the XML
  with XPath rather than just telling it to ignore them, but I have no
  idea what the namespaces are.

## Disclaimer

I'm not affiliated with Baupost, nor with any other party mentioned
here, nor should anything I wrote above be taken as investment or
financial advice, nor do I warrant that the code does anything it
claims to.  I am not your lawyer.  I am not your financial advisor.  I
am not responsible for what you do with money.
