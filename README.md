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

The R script handles XML tables like the above.

The code is still in need of some organization...
