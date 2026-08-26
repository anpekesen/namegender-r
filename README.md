# namegender for R

```r
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
result <- ng_name(client, "Ayşe", country = "TR")
result$gender
```
