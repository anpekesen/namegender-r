skip_if_not(exists("local_mocked_responses", asNamespace("httr2")), "httr2 >= 1.0.0 needed for mocked responses")

client <- namegender("test_key", base_url = "https://api.test/api/v1")
json_response <- function(status_code, body) {
  httr2::response(status_code = status_code, headers = list(`Content-Type` = "application/json"),
                  body = charToRaw(as.character(body)))
}
# httr2 keeps a JSON body as the R list until it is sent; encode it the way
# req_body_json() does to see what goes on the wire.
sent_json <- function(req) {
  data <- req$body$data
  text <- if (is.raw(data)) rawToChar(data) else as.character(jsonlite::toJSON(data, auto_unbox = TRUE, null = "null"))
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

test_that("lookups send locale and ip and return country_source", {
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1]] <<- req
    json_response(200, '{"name":"Andrea","gender":"male","country":"IT","country_source":"locale"}')
  })

  result <- ng_name(client, "Andrea", locale = "it-IT", ip = "203.0.113.7")
  expect_equal(result$country_source, "locale")
  expect_match(requests[[1]]$url, "/gender$")
  expect_equal(sent_json(requests[[1]]), list(name = "Andrea", locale = "it-IT", ip = "203.0.113.7"))

  ng_email(client, "andrea@example.com", ip = "203.0.113.7")
  expect_equal(sent_json(requests[[2]]), list(email = "andrea@example.com", ip = "203.0.113.7"))

  ng_username(client, "andrea_r", "IT", "it-IT")
  expect_equal(sent_json(requests[[3]]), list(username = "andrea_r", country = "IT", locale = "it-IT"))
})

test_that("lookups leave locale and ip out when not given", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, '{"name":"Ayse","gender":"female","country":null,"country_source":null}')
  })
  result <- ng_name(client, "Ayse", best_guess = TRUE)
  expect_equal(body, list(name = "Ayse", best_guess = TRUE))
  expect_null(result$country_source)
})

test_that("bulk sends locale and ip, and country_source is on the envelope", {
  body <- NULL
  httr2::local_mocked_responses(function(req) {
    body <<- sent_json(req)
    json_response(200, '{"results":[{"name":"Andrea","gender":"male"},{"name":"Maria","gender":"female"}],"took_ms":3,"country_source":"ip"}')
  })
  result <- ng_bulk(client, c("Andrea", "Maria"), locale = "en", ip = "203.0.113.7")
  expect_equal(body, list(names = list("Andrea", "Maria"), type = "name", locale = "en", ip = "203.0.113.7"))
  expect_equal(result$country_source, "ip")
  expect_false("country_source" %in% names(result$results))
})
