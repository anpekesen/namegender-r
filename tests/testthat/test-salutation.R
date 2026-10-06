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

anna <- '{"query":"Dr. Anna Müller","language":"de","form":"gendered","reason":null,
  "salutation":{"formal":"Sehr geehrte Frau Dr. Müller,","informal":"Liebe Anna,","neutral":"Guten Tag Dr. Anna Müller,"},
  "parts":{"opening":"Sehr geehrte","courtesy":"Frau","academic":"Dr.","name":"Müller"},
  "gender":"female","gender_source":"lookup","probability":99,"confidence":"high",
  "first_name":"Anna","last_name":"Müller","name_type":"personal","country":"DE"}'
kim <- '{"query":"Kim Schmidt","language":"de","form":"neutral","reason":"below_min_probability",
  "salutation":{"formal":"Guten Tag Kim Schmidt,","informal":"Hallo Kim,","neutral":"Guten Tag Kim Schmidt,"},
  "parts":{"opening":"Guten Tag","courtesy":null,"academic":null,"name":"Kim Schmidt"},
  "gender":null,"gender_source":null,"probability":null,"confidence":null,
  "first_name":"Kim","last_name":"Schmidt","name_type":"personal","country":"DE"}'
firm <- '{"query":"Müller GmbH","language":"de","form":"organization","reason":null,
  "salutation":{"formal":"Sehr geehrte Damen und Herren,","informal":"Hallo,","neutral":"Sehr geehrte Damen und Herren,"},
  "parts":{"opening":"Sehr geehrte Damen und Herren","courtesy":null,"academic":null,"name":null},
  "gender":null,"gender_source":null,"probability":null,"confidence":null,
  "first_name":null,"last_name":null,"name_type":"organization","country":"DE"}'
envelope <- function(item) {
  sub("^\\{", '{"credits_charged":1,"credits_remaining":4999,"data_version":"2026.10","request_id":"req_1","country_source":null,', item)
}

test_that("salutation sends only the arguments that are set", {
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1]] <<- req
    json_response(200, envelope(anna))
  })

  ng_salutation(client, "Dr. Anna Müller")
  expect_match(requests[[1]]$url, "/salutation$")
  expect_equal(sent_json(requests[[1]]), list(name = "Dr. Anna Müller"))

  ng_salutation(client, "Dr. Anna Müller", language = "de", country = "DE", locale = "de-AT", ip = "203.0.113.7",
                gender = "female", min_probability = 80, title = "Dr.")
  expect_equal(sent_json(requests[[2]]), list(
    name = "Dr. Anna Müller", language = "de", country = "DE", locale = "de-AT", ip = "203.0.113.7",
    gender = "female", min_probability = 80L, title = "Dr."
  ))

  ng_salutation(client, first_name = "Anna", last_name = "Müller", locale = "de-DE")
  expect_equal(sent_json(requests[[3]]), list(first_name = "Anna", last_name = "Müller", locale = "de-DE"))
})

test_that("salutation does not take gender lookup options", {
  expect_error(ng_salutation(client, "Kim Schmidt", best_guess = TRUE), "unused argument")
  expect_error(ng_salutation_bulk(client, "Kim Schmidt", ai_fallback = TRUE), "unused argument")
})

test_that("salutation parses the gendered form", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(anna)))
  result <- ng_salutation(client, "Dr. Anna Müller", language = "de")
  expect_equal(result$form, "gendered")
  expect_null(result$reason)
  expect_equal(result$salutation$formal, "Sehr geehrte Frau Dr. Müller,")
  expect_equal(result$salutation$informal, "Liebe Anna,")
  expect_equal(result$salutation$neutral, "Guten Tag Dr. Anna Müller,")
  expect_equal(result$parts, list(opening = "Sehr geehrte", courtesy = "Frau", academic = "Dr.", name = "Müller"))
  expect_equal(result$probability, 99)
  expect_equal(result$credits_charged, 1)
  expect_equal(result$data_version, "2026.10")
})

test_that("salutation parses the neutral form with a reason and null parts", {
  httr2::local_mocked_responses(function(req) json_response(200, envelope(kim)))
  result <- ng_salutation(client, "Kim Schmidt", language = "de")
  expect_equal(result$form, "neutral")
  expect_equal(result$reason, "below_min_probability")
  expect_equal(result$salutation$formal, "Guten Tag Kim Schmidt,")
  expect_true("courtesy" %in% names(result$parts))
  expect_null(result$parts$courtesy)
  expect_null(result$parts$academic)
  expect_null(result$gender)
  expect_null(result$probability)
})

test_that("salutation bulk keeps the input order and the summary", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, paste0(
      '{"credits_charged":3,"credits_remaining":4996,"data_version":"2026.10","request_id":"req_2","took_ms":4,',
      '"country_source":null,"language":"de",',
      '"summary":{"total":3,"gendered":1,"neutral":1,"organization":1},',
      '"results":[', firm, ",", anna, ",", kim, "]}"
    ))
  })
  names <- c("Müller GmbH", "Dr. Anna Müller", "Kim Schmidt")
  result <- ng_salutation_bulk(client, names, language = "de", min_probability = 95)
  expect_equal(body, list(names = as.list(names), language = "de", min_probability = 95L))
  expect_equal(result$results$query, names)
  expect_equal(result$results$form, c("organization", "gendered", "neutral"))
  expect_equal(result$results$reason, c(NA, NA, "below_min_probability"))
  expect_equal(result$results$salutation$formal,
               c("Sehr geehrte Damen und Herren,", "Sehr geehrte Frau Dr. Müller,", "Guten Tag Kim Schmidt,"))
  expect_equal(result$summary, list(total = 3, gendered = 1, neutral = 1, organization = 1))
  expect_equal(result$credits_charged, 3)
  expect_false("credits_charged" %in% names(result$results))
})

test_that("salutation bulk sends one name as an array", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, paste0('{"summary":{"total":1,"gendered":0,"neutral":1,"organization":0},"results":[', kim, "]}"))
  })
  ng_salutation_bulk(client, "Kim Schmidt")
  expect_equal(body, list(names = list("Kim Schmidt")))
})

test_that("an unsupported language is a namegender_error", {
  httr2::local_mocked_responses(function(req) json_response(422, paste0(
    '{"error":"invalid_input","message":"Unsupported language.","field":"language",',
    '"supported":["en","de","tr"],"request_id":"req_9"}'
  )))
  error <- expect_error(ng_salutation(client, "Dr. Anna Müller", language = "xx"), "Unsupported language.",
                        class = "namegender_error")
  expect_equal(error$status, 422)
  expect_equal(error$body$error, "invalid_input")
  expect_equal(error$body$field, "language")
  expect_true("de" %in% error$body$supported)
})
