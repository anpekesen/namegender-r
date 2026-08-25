# genderscope for R

```r
client <- genderscope(Sys.getenv("GENDERSCOPE_API_KEY"))
result <- gs_name(client, "Ayşe", country = "TR")
result$gender
```
