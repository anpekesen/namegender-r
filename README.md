# namegender for R

```r
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
result <- ng_name(client, "Ayşe", country = "TR")
result$gender
```

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
