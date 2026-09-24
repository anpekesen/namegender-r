skip_if_not(exists("local_mocked_responses", asNamespace("httr2")), "httr2 >= 1.0.0 needed for mocked responses")

client <- namegender("test_key", base_url = "https://api.test/api/v1")
job_json <- function(status, ...) {
  jsonlite::toJSON(c(list(id = "B-1", status = status), list(...)), auto_unbox = TRUE)
}
json_response <- function(status_code, body) {
  httr2::response(status_code = status_code, headers = list(`Content-Type` = "application/json"),
                  body = charToRaw(as.character(body)))
}
sample_file <- function() {
  path <- tempfile(fileext = ".csv")
  writeLines(c("id,first_name", "1,Ayse"), path)
  path
}

test_that("create sends multipart with settings and one key on every retry", {
  sleeps <- numeric()
  local_mocked_bindings(ng_sleep = function(seconds) sleeps <<- c(sleeps, seconds))
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1]] <<- req
    if (length(requests) < 3) json_response(503, '{"error":"unavailable","message":"Down"}')
    else json_response(202, job_json("queued"))
  })

  job <- ng_batch_create(client, sample_file(), name_column = "first_name", best_guess = TRUE)
  expect_equal(job$status, "queued")
  expect_length(requests, 3)
  expect_equal(sleeps, c(1, 2))
  keys <- vapply(requests, function(req) req$headers$`Idempotency-Key`, character(1))
  expect_equal(length(unique(keys)), 1)
  expect_true(nzchar(keys[[1]]))

  body <- rawToChar(requests[[1]]$body$data)
  content_types <- unlist(requests[[1]]$body[c("type", "content_type")])
  expect_true(any(grepl("^multipart/form-data; boundary=", content_types)))
  expect_match(body, 'name="start"\r\n\r\ntrue', fixed = TRUE)
  expect_match(body, 'name="name_column"\r\n\r\nfirst_name', fixed = TRUE)
  expect_match(body, 'name="best_guess"\r\n\r\ntrue', fixed = TRUE)
  expect_match(body, 'filename="file[0-9a-f]+\\.csv"')
  expect_false(grepl('name="country"', body, fixed = TRUE))
})

test_that("create uses a given key and stops after the retries", {
  local_mocked_bindings(ng_sleep = function(seconds) NULL)
  keys <- character()
  httr2::local_mocked_responses(function(req) {
    keys <<- c(keys, req$headers$`Idempotency-Key`)
    json_response(502, '{"message":"Bad gateway"}')
  })
  expect_error(ng_batch_create(client, sample_file(), name_column = "first_name", idempotency_key = "my-key", retries = 1),
               class = "namegender_error")
  expect_equal(keys, c("my-key", "my-key"))
})

test_that("create retries a connection error", {
  local_mocked_bindings(ng_sleep = function(seconds) NULL)
  calls <- 0
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1
    if (calls == 1) stop("Could not connect") else json_response(202, job_json("queued"))
  })
  expect_equal(ng_batch_create(client, sample_file(), name_column = "first_name")$status, "queued")
  expect_equal(calls, 2)
})

test_that("create never retries a 4xx and keeps the API body", {
  local_mocked_bindings(ng_sleep = function(seconds) stop("should not sleep"))
  calls <- 0
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1
    json_response(422, '{"error":"invalid_input","message":"Unknown column","columns":["id","first_name"]}')
  })
  error <- tryCatch(ng_batch_create(client, sample_file(), name_column = "ad"), namegender_error = function(e) e)
  expect_equal(calls, 1)
  expect_equal(error$status, 422)
  expect_equal(error$body$error, "invalid_input")
  expect_equal(error$body$columns, c("id", "first_name"))
})

test_that("cancel accepts an empty 204", {
  httr2::local_mocked_responses(function(req) {
    expect_equal(req$method, "DELETE")
    httr2::response(status_code = 204)
  })
  expect_null(ng_batch_cancel(client, "B-1"))
})

test_that("wait polls until the job finishes and returns a failed job", {
  sleeps <- numeric()
  local_mocked_bindings(ng_sleep = function(seconds) sleeps <<- c(sleeps, seconds))
  replies <- list(job_json("queued", poll_after_seconds = 2), job_json("processing"), job_json("failed"))
  seen <- character()
  httr2::local_mocked_responses(function(req) {
    reply <- replies[[1]]
    replies <<- replies[-1]
    json_response(200, reply)
  })
  job <- ng_batch_wait(client, "B-1", on_progress = function(j) seen <<- c(seen, j$status))
  expect_equal(job$status, "failed")
  expect_equal(seen, c("queued", "processing", "failed"))
  expect_equal(sleeps, c(2, 5))
})

test_that("wait stops at the timeout", {
  local_mocked_bindings(ng_sleep = function(seconds) NULL)
  httr2::local_mocked_responses(function(req) json_response(200, job_json("processing", poll_after_seconds = 10)))
  expect_error(ng_batch_wait(client, "B-1", timeout = 5), class = "namegender_error", regexp = "Timed out")
})

test_that("download returns raw bytes or writes a file", {
  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 200, headers = list(`Content-Type` = "text/csv"), body = as.raw(c(0xef, 0xbb, 0xbf, 0x61)))
  })
  expect_equal(ng_batch_download(client, "B-1"), as.raw(c(0xef, 0xbb, 0xbf, 0x61)))
  path <- tempfile(fileext = ".csv")
  expect_invisible(ng_batch_download(client, "B-1", path))
  expect_equal(readBin(path, "raw", 10), as.raw(c(0xef, 0xbb, 0xbf, 0x61)))
})
