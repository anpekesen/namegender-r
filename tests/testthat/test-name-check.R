skip_if_not(exists("local_mocked_responses", asNamespace("httr2")), "httr2 >= 1.0.0 needed for mocked responses")

client <- namegender("test_key", base_url = "https://api.test/api/v1")
json_response <- function(status_code, body) {
  httr2::response(status_code = status_code, headers = list(`Content-Type` = "application/json"),
                  body = charToRaw(enc2utf8(as.character(body))))
}
sent_json <- function(req) {
  data <- req$body$data
  text <- if (is.raw(data)) rawToChar(data) else as.character(jsonlite::toJSON(data, auto_unbox = TRUE, null = "null"))
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

asdf <- '{"query":"asdf qwerty","assessment":"implausible","score":0,
  "signals":[{"code":"keyboard_pattern","severity":"high","part":"first_name","value":"asdf"},
             {"code":"keyboard_pattern","severity":"high","part":"last_name","value":"qwerty"},
             {"code":"first_name_not_found","severity":"medium","part":"first_name","value":null}],
  "first_name":"Asdf","last_name":"Qwerty","name_type":"personal",
  "evidence":{"first_name_status":"not_found","first_name_counted_records":0}}'
jennifer <- '{"query":"Jennifer Null","assessment":"plausible","score":96,
  "signals":[{"code":"first_name_attested","severity":"positive","part":"first_name","value":"Jennifer"}],
  "first_name":"Jennifer","last_name":"Null","name_type":"personal",
  "evidence":{"first_name_status":"counted","first_name_counted_records":1470000}}'
acme <- '{"query":"Acme Ltd","assessment":"suspicious","score":40,
  "signals":[{"code":"organization_name","severity":"medium","part":null,"value":null}],
  "first_name":null,"last_name":null,"name_type":"organization",
  "evidence":{"first_name_status":null,"first_name_counted_records":0}}'
envelope <- function(item) {
  sub("^\\{", '{"credits_charged":1,"credits_remaining":4999,"data_version":"2026.10","request_id":"req_1","country_source":null,', item)
}

test_that("name check sends only the arguments that are set", {
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1]] <<- req
    json_response(200, envelope(asdf))
  })

  ng_name_check(client, "asdf qwerty")
  expect_match(requests[[1]]$url, "/name-check$")
  expect_equal(sent_json(requests[[1]]), list(name = "asdf qwerty"))

  ng_name_check(client, "Jennifer Null", country = "US", locale = "en-US", ip = "203.0.113.7")
  expect_equal(sent_json(requests[[2]]), list(
    name = "Jennifer Null", country = "US", locale = "en-US", ip = "203.0.113.7"
  ))

  ng_name_check(client, first_name = "Jennifer", last_name = "Null", locale = "en-US")
  expect_equal(sent_json(requests[[3]]), list(first_name = "Jennifer", last_name = "Null", locale = "en-US"))
})

test_that("name check does not take gender lookup options", {
  expect_error(ng_name_check(client, "asdf qwerty", best_guess = TRUE), "unused argument")
  expect_error(ng_name_check(client, "asdf qwerty", language = "en"), "unused argument")
  expect_error(ng_name_check_bulk(client, "asdf qwerty", ai_fallback = TRUE), "unused argument")
})

test_that("name check parses assessment, score, signals and evidence", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(asdf)))
  result <- ng_name_check(client, "asdf qwerty")
  expect_equal(result$assessment, "implausible")
  expect_equal(result$score, 0)
  expect_equal(result$first_name, "Asdf")
  expect_equal(result$last_name, "Qwerty")
  expect_equal(result$name_type, "personal")
  expect_s3_class(result$signals, "data.frame")
  expect_equal(result$signals$code, c("keyboard_pattern", "keyboard_pattern", "first_name_not_found"))
  expect_equal(result$signals$severity, c("high", "high", "medium"))
  expect_equal(result$signals$part, c("first_name", "last_name", "first_name"))
  expect_equal(result$signals$value, c("asdf", "qwerty", NA))
  expect_equal(result$evidence, list(first_name_status = "not_found", first_name_counted_records = 0))
  expect_true("country_source" %in% names(result))
  expect_null(result$country_source)
  expect_equal(result$credits_charged, 1)
  expect_equal(result$data_version, "2026.10")
  expect_equal(result$request_id, "req_1")
})

test_that("name check keeps null part, value and first_name_status", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(acme)))
  result <- ng_name_check(client, "Acme Ltd")
  expect_equal(result$assessment, "suspicious")
  expect_equal(result$name_type, "organization")
  expect_equal(result$signals$code, "organization_name")
  expect_true(is.na(result$signals$part))
  expect_true(is.na(result$signals$value))
  expect_null(result$first_name)
  expect_true("first_name_status" %in% names(result$evidence))
  expect_null(result$evidence$first_name_status)
  expect_equal(result$evidence$first_name_counted_records, 0)
})

test_that("name check bulk keeps the input order and the summary", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, paste0(
      '{"credits_charged":3,"credits_remaining":4996,"data_version":"2026.10","request_id":"req_2","took_ms":4,',
      '"country_source":"country",',
      '"summary":{"total":3,"plausible":1,"suspicious":1,"implausible":1},',
      '"results":[', jennifer, ",", asdf, ",", acme, "]}"
    ))
  })
  names <- c("Jennifer Null", "asdf qwerty", "Acme Ltd")
  result <- ng_name_check_bulk(client, names, country = "US")
  expect_equal(body, list(names = as.list(names), country = "US"))
  expect_equal(result$results$query, names)
  expect_equal(result$results$assessment, c("plausible", "implausible", "suspicious"))
  expect_equal(result$results$score, c(96, 0, 40))
  expect_equal(result$results$evidence$first_name_status, c("counted", "not_found", NA))
  expect_equal(result$results$signals[[2]]$value, c("asdf", "qwerty", NA))
  expect_equal(result$summary, list(total = 3, plausible = 1, suspicious = 1, implausible = 1))
  expect_equal(result$credits_charged, 3)
  expect_equal(result$country_source, "country")
  expect_false("credits_charged" %in% names(result$results))
})

test_that("name check bulk sends one name as an array", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, paste0('{"summary":{"total":1,"plausible":0,"suspicious":0,"implausible":1},"results":[', asdf, "]}"))
  })
  ng_name_check_bulk(client, "asdf qwerty")
  expect_equal(body, list(names = list("asdf qwerty")))
})

test_that("a missing name is a namegender_error", {
  httr2::local_mocked_responses(function(req) json_response(400, paste0(
    '{"error":"missing_input","message":"Send name, or first_name and last_name.","request_id":"req_9"}'
  )))
  error <- expect_error(ng_name_check(client), "Send name, or first_name and last_name.", class = "namegender_error")
  expect_equal(error$status, 400)
  expect_equal(error$body$error, "missing_input")
  expect_equal(error$body$request_id, "req_9")
})
