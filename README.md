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

A result carries `query`, `name`, `first_name`, `middle_name`, `last_name`, `name_type`, `gender`, `country`, `probability`,
`sample_size`, `took_ms`, `source`, `confidence` and `matched_as`, alongside
`credits_charged`, `credits_remaining`, `data_version` and `request_id`.
Success is the HTTP status: a non-2xx response stops with the API's `message`.

## Country hints

Without a `country`, pass what you know about your end user and the API picks
the country from it: `locale` (a language tag such as `"it-IT"` or `"pt_BR"`;
a tag without a region, such as `"en"`, sets no country) or `ip` (the user's
IP address, not stored by the API). The priority is `country` > `locale` > `ip`.

```r
result <- ng_name(client, "Andrea", locale = "it-IT", ip = "203.0.113.7")
result$country_source   # "country", "locale", "ip", or NULL when none applied
```

`ng_email()`, `ng_username()` and `ng_bulk()` take the same arguments. For
`ng_bulk()`, `country_source` is on the response envelope (next to `took_ms`),
not on each row of `results`. File jobs and `ng_countries()` do not take them.

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

## Salutation

A ready-to-use salutation for a letter or an email, in `en`, `de`, `fr`, `es`,
`it`, `pt`, `nl`, `tr`, `pl` or `ja` (and regional variants such as `de-AT`
or `pt-BR`). Without `language` it follows `locale`, then the country, then
English.

```r
result <- ng_salutation(client, "Dr. Anna Müller", language = "de")
result$salutation$formal     # "Sehr geehrte Frau Dr. Müller,"
result$salutation$informal   # "Liebe Anna,"

ng_salutation(client, "Ahmet Yılmaz", language = "tr")$salutation$formal   # "Sayın Ahmet Bey,"

# Names stored in separate fields are used as they are, not parsed:
ng_salutation(client, first_name = "Anna", last_name = "Müller", title = "Dr.", language = "de")

bulk <- ng_salutation_bulk(client, c("Dr. Anna Müller", "Müller GmbH"), language = "de")
bulk$results$salutation$formal
bulk$summary   # total, gendered, neutral, organization
```

One credit per name. When the gender is not certain enough (`min_probability`,
default 90), you get the neutral form rather than a guess: `form` is
`"gendered"`, `"neutral"` or `"organization"`, and `reason` says why it is not
gendered (`"gender_unknown"`, `"below_min_probability"`, ...). `best_guess`
does not apply here. If you already know the gender, pass `gender = "female"`,
`"male"` or `"neutral"`. `ng_salutation_bulk()` takes up to 100 names and
returns `results` in input order. An unsupported language is a
`namegender_error` with `status` 422 and `body$supported`.

## Name check

Whether a name typed into a form looks like a real person's name, with the
reasons. It never calls a name fake: use it to flag records for a closer look,
not to reject people automatically.

```r
result <- ng_name_check(client, "asdf qwerty")
result$assessment   # "implausible"
result$score        # 0 (0-100)
result$signals      # data frame: code, severity, part, value

ng_name_check(client, "Jennifer Null")$assessment   # "plausible"

# Names stored in separate fields are used as they are, not parsed:
ng_name_check(client, first_name = "Jennifer", last_name = "Null", country = "US")

bulk <- ng_name_check_bulk(client, c("Jennifer Null", "asdf qwerty"))
bulk$results[, c("query", "assessment", "score")]
bulk$summary   # total, plausible, suspicious, implausible
```

One credit per name. `assessment` is `"plausible"`, `"suspicious"` or
`"implausible"`; each signal has `code`, `severity` (`high`, `medium`, `low`,
`info`, `positive`), `part` and `value` (either can be `NA`). `evidence` says
whether the first name is counted, attested or not found. Surnames are judged
by their shape only. It takes `country`, `locale` and `ip`, not `best_guess`
or `ai_fallback`. `ng_name_check_bulk()` takes up to 100 names and returns
`results` in input order.

## File jobs

Upload a CSV or XLSX file (up to 100 MB and 1,000,000 rows) and get it back
with gender columns added. One credit per row, charged only if the job
completes.

```r
job <- ng_batch_create(client, "customers.csv",
  name_column = "first_name",   # required to start
  country_column = "country"    # optional: a country code per row
)

done <- ng_batch_wait(client, job$id, on_progress = function(j) message(j$progress, "%"))
if (done$status == "failed") stop(done$error$code)

ng_batch_download(client, done$id, "customers-gender.csv")
result <- read.csv("customers-gender.csv", fileEncoding = "UTF-8-BOM")
```

`name_column` is required to start: a guessed column that turns out to be
wrong would spend credits on the wrong data. To see the columns and the cost
first, upload with `start = FALSE`, read `job$inspection`, then call
`ng_batch_start(client, job$id, name_column = ...)`.

`ng_batch_create()` sends an `Idempotency-Key` and retries connection errors and
502/503/504 with the same key, so a retry never opens a second job. Pass your
own `idempotency_key` to keep that guarantee across your own retries.

`ng_batch_wait()` returns a failed job rather than stopping; branch on
`job$error$code`. `ng_batch_cancel()` returns the credit of a job that has not
started, and deletes a finished one. `ng_batch_list(client, limit =, page =)`
includes jobs started from the dashboard. Up to three jobs can be queued or
running at once; a fourth is refused with `429 too_many_batches`.

An API error is a condition of class `namegender_error` carrying `status` and
`body` (`error`, `message`, `request_id`, `docs`). Branch on `body$error`, not
on the message:

```r
tryCatch(
  ng_batch_create(client, "customers.csv", name_column = "ad"),
  namegender_error = function(e) if (identical(e$body$error, "invalid_input")) print(e$body$columns) else stop(e)
)
```

The result appends `gender`, `probability`, `sample_size`, `country`, `source`,
`matched_as`, `first_name`, `middle_name`, `last_name` and `name_type` to every
row. A CSV result starts with a UTF-8 byte order mark; read it with
`fileEncoding = "UTF-8-BOM"`. `ng_batch_download()` without a path returns the
file as a raw vector.

## Webhooks

Add an endpoint under Webhooks in the dashboard, and NameGender sends a signed
`POST` to it when a file job completes or fails, and when credits are about to
run out (`credits.low`) or have run out (`credits.depleted`, checked hourly).
`ng_webhook_verify()` checks the signature and the timestamp, and returns the
event.

```r
# plumber.R
#* @post /namegender
#* @serializer unboxedJSON
function(req, res) {
  event <- tryCatch(
    namegender::ng_webhook_verify(
      req$bodyRaw,                      # the raw bytes, not the parsed body
      req$HTTP_NAMEGENDER_SIGNATURE,
      Sys.getenv("NAMEGENDER_WEBHOOK_SECRET")
    ),
    namegender_webhook_error = function(e) NULL
  )
  if (is.null(event)) {
    res$status <- 400
    return(list())
  }

  if (event$type == "batch.completed") {
    job <- event$data$object   # the job, as ng_batch_get() returns it
    # ...
  }
  res$status <- 204
  list()
}
```

Answer quickly and do slow work afterwards. Anything other than a 2xx within 10
seconds is retried, up to 8 attempts over about 45 hours. Use `event$id` (also
the `NameGender-Event-Id` header) to ignore a delivery you have already
handled: a retry carries the same id, and order is not guaranteed.
