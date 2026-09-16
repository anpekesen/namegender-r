# namegender for R

```r
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
result <- ng_name(client, "Ayşe", country = "TR")
result$gender
result$sample_size
```

## Options and response

`ng_name()`, `ng_email()`, `ng_username()` and `ng_bulk()` pass extra
arguments to the API, such as `ai_fallback = TRUE` and `best_guess = TRUE`:

```r
ng_name(client, "Andrea", country = "IT", best_guess = TRUE)
```

A result carries `query`, `name`, `gender`, `country`, `probability`,
`sample_size`, `took_ms`, `source`, `confidence` and `matched_as`, alongside
`credits_charged`, `credits_remaining`, `data_version` and `request_id`.
Success is the HTTP status: a non-2xx response stops with the API's `message`.

## Country distribution

Which countries a name is recorded in. This is not a country-of-origin or
ethnicity inference: `registrations` is counted volume, comparable only among
the countries that publish counted birth statistics, and `attested_in` is
presence with no weight attached. Show `basis$note` next to any percentage.

```r
dist <- ng_countries(client, "Mehmet", limit = 10)
dist$registrations[, c("country", "share")]
dist$attested_in
```
