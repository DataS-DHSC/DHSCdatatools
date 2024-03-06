
<!-- README.md is generated from README.Rmd. Please edit that file -->

# DHSCdatatools

The goal of DHSCdatatools is to provide a suite of tools for using data
hosted on the DHSC analytical cloud (DAC) platform.

## Installation

You can install DHSCdatatools from [GitHub](https://github.com/) with:

``` r
if (!requireNamespace("librarian")) install.packages("librarian")
librarian::stock(DataS-DHSC/DHSCdatatools)
```

Once installed you will also need to update the *.Renviron* file in the
root folder of your RStudio project with the relevant `DAC_TENANT` and
`KEY_VAULT_NAME` keys. A .Renviron file with the default settings can be
found in the *R files* folder of the *DAC* channel on the *Data Science*
Teams space.

#### IMPORTANT

Never commit your *.Renviron* to git or upload to GitHub. To ensure git
ignores the file add it to the project’s .gitignore using the following
command (you may need to install the `usethis` package first):
`usethis::use_git_ignore(".Renviron")`.

If you do accidentally commit your *.Renviron* file (or any other
sensitive data) please get in touch with the [Data Science
Hub](mailto:datascience@dhsc.gov.uk) to discuss how best to mitigate the
breach.

## Example

### Connecting to the SQL endpoint

To connect to the DAC SQL endpoint and access data from, for example,
the *samples.default.mtcars* table use:

``` r
library(DHSCdatatools)
library(tidyverse)
library(dbplyr)

# Get connection
con <- dac_connect(connections_pane = TRUE)

# Table to query - path normally given in the form "<catalog>.<schema>.<table>"
table_path <- in_catalog("samples", "default", "mtcars")

# Query table and collect results from server
# can use any dplyr verbs supported by odbc driver
df <- tbl(con, table_path) |> 
  group_by(cyl) |> 
  summarise(mpg = mean(mpg, na.rm = TRUE)) |>
  arrange(desc(mpg))

# Queries are lazily evaluated (meaning nothing is run until needed and as much
# processing is done on the remote server as possible).
print(df)
df |> collect() |> view()

# it is also possible to run SQL directly
df <- dbGetQuery(con, "SELECT * FROM samples.default.mtcars")

# close the connection if no longer used
dbDisconnect(con)
```

## Code of Conduct

Please note that the DHSCdatatools project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.

## Licence

Unless stated otherwise, the codebase is released under the MIT License.
This covers both the codebase and any sample code in the documentation.

All other content is [© Crown
copyright](http://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/)
and available under the terms of the [Open Government 3.0
licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/),
except where otherwise stated.
