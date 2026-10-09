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

brittany <- '{"name":"Brittany","first_name":"Brittany","gender":null,
  "age":36,"age_range":{"low":32,"high":38},"age_range_80":{"low":28,"high":41},
  "birth_year":1990,"sample_size":353775,"births":361434,
  "country":"US","country_source":"default",
  "source":"ssa","series":"1880-2024","reference_year":2026,"reason":null}'
yuki <- '{"name":"Yuki","first_name":"Yuki","gender":null,
  "age":null,"age_range":null,"age_range_80":null,
  "birth_year":null,"sample_size":0,"births":0,
  "country":"JP","country_source":"country",
  "source":null,"series":null,"reference_year":2026,"reason":"country_not_covered"}'
envelope <- function(item, charged = 1) {
  sub("^\\{", paste0('{"credits_charged":', charged, ',"credits_remaining":49999,"request_id":"req_1",'), item)
}

test_that("age sends only the arguments that are set", {
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1]] <<- req
    json_response(200, envelope(brittany))
  })

  ng_age(client, "Brittany")
  expect_match(requests[[1]]$url, "/age$")
  expect_equal(requests[[1]]$method, "POST")
  expect_equal(sent_json(requests[[1]]), list(name = "Brittany"))

  ng_age(client, "Brittany", gender = "female", country = "US", locale = "en-US", ip = "203.0.113.7")
  expect_equal(sent_json(requests[[2]]), list(
    name = "Brittany", gender = "female", country = "US", locale = "en-US", ip = "203.0.113.7"
  ))

  ng_age(client, "Brittany", locale = "fr-FR")
  expect_equal(sent_json(requests[[3]]), list(name = "Brittany", locale = "fr-FR"))
})

test_that("age does not take gender lookup options", {
  expect_error(ng_age(client, "Brittany", best_guess = TRUE), "unused argument")
  expect_error(ng_age_bulk(client, "Brittany", ai_fallback = TRUE), "unused argument")
})

test_that("age parses the median, both ranges and the source", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(brittany)))
  result <- ng_age(client, "Brittany")
  expect_equal(result$name, "Brittany")
  expect_equal(result$first_name, "Brittany")
  expect_true("gender" %in% names(result))
  expect_null(result$gender)
  expect_equal(result$age, 36)
  expect_equal(result$age_range, list(low = 32, high = 38))
  expect_equal(result$age_range_80, list(low = 28, high = 41))
  expect_equal(result$birth_year, 1990)
  expect_equal(result$sample_size, 353775)
  expect_equal(result$births, 361434)
  expect_equal(result$country, "US")
  expect_equal(result$country_source, "default")
  expect_equal(result$source, "ssa")
  expect_equal(result$series, "1880-2024")
  expect_equal(result$reference_year, 2026)
  expect_true("reason" %in% names(result))
  expect_null(result$reason)
  expect_equal(result$credits_charged, 1)
  expect_equal(result$credits_remaining, 49999)
  expect_equal(result$request_id, "req_1")
  expect_false("data_version" %in% names(result))
})

test_that("a country that is not covered is an answer with a null age", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(yuki, charged = 0)))
  result <- ng_age(client, "Yuki", country = "JP")
  expect_null(result$age)
  expect_null(result$age_range)
  expect_null(result$age_range_80)
  expect_null(result$birth_year)
  expect_null(result$source)
  expect_equal(result$reason, "country_not_covered")
  expect_equal(result$country, "JP")
  expect_equal(result$country_source, "country")
  expect_equal(result$credits_charged, 0)
})

test_that("age bulk keeps the input order", {
  body <- NULL
  url <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    url <<- req$url
    json_response(200, paste0(
      '{"credits_charged":1,"credits_remaining":49998,"request_id":"req_2","country_source":"country",',
      '"results":[', brittany, ",", yuki, "]}"
    ))
  })
  names <- c("Brittany", "Yuki")
  result <- ng_age_bulk(client, names, gender = "female", country = "US")
  expect_match(url, "/age/bulk$")
  expect_equal(body, list(names = as.list(names), gender = "female", country = "US"))
  expect_equal(result$results$name, names)
  expect_equal(result$results$age, c(36, NA))
  expect_equal(result$results$age_range$low, c(32, NA))
  expect_equal(result$results$age_range_80$high, c(41, NA))
  expect_equal(result$results$reason, c(NA, "country_not_covered"))
  expect_equal(result$credits_charged, 1)
  expect_equal(result$country_source, "country")
  expect_false("credits_charged" %in% names(result$results))
})

test_that("age bulk sends one name as an array", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, paste0('{"results":[', brittany, "]}"))
  })
  ng_age_bulk(client, "Brittany")
  expect_equal(body, list(names = list("Brittany")))
})

test_that("an invalid gender is a namegender_error", {
  httr2::local_mocked_responses(function(req) json_response(422, paste0(
    '{"error":"invalid_gender","message":"gender must be male or female.","request_id":"req_9"}'
  )))
  error <- expect_error(ng_age(client, "Brittany", gender = "x"), "gender must be male or female.", class = "namegender_error")
  expect_equal(error$status, 422)
  expect_equal(error$body$error, "invalid_gender")
  expect_equal(error$body$request_id, "req_9")
})
