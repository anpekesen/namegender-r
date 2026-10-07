## Submission

This is a new submission.

The package is a client for the 'NameGender' web API
<https://namegender.com>, which infers the likely gender of a name from
official name statistics. Every answer reports the number of records behind
it and the data version that produced it, which is why researchers use it.

## R CMD check results

0 errors | 0 warnings | 1 note

* New submission.

## Examples and tests

Every function except `ng_webhook_verify()` calls the web API and needs a
personal API key, so those examples are wrapped in `\dontrun{}`.
`ng_webhook_verify()` works offline and its example runs.

The tests never call the network: requests are checked with a mocked
transport, so they pass on CRAN machines without a key or internet access.

`ng_batch_download()` writes only to the path the user passes.
