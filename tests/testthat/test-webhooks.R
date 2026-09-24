# Diğer SDK'larla ortak test vektörü: aynı gizli anahtar, gövde ve başlık her
# dilde aynı sonucu vermeli.
secret <- "whsec_test_vector"
body <- '{"id":"evt_1","type":"webhook.test"}'
signature <- "857fcddfea47617c448b7a8e6537bbd59c9922a37c5273b2709812fbadb29e50"
header <- paste0("t=1700000000,v1=", signature)
now <- 1700000000

test_that("the shared vector verifies and returns the event", {
  event <- ng_webhook_verify(body, header, secret, now = now)
  expect_equal(event$id, "evt_1")
  expect_equal(event$type, "webhook.test")
})

test_that("a raw body verifies the same as a string", {
  event <- ng_webhook_verify(charToRaw(body), header, secret, now = now)
  expect_equal(event$id, "evt_1")
})

test_that("any v1 matching is enough during a secret rotation", {
  rotated <- paste0("t=1700000000,v1=", strrep("0", 64), ",v1=", signature)
  expect_equal(ng_webhook_verify(body, rotated, secret, now = now)$id, "evt_1")
})

test_that("a tampered body is rejected", {
  expect_error(ng_webhook_verify(sub("evt_1", "evt_2", body), header, secret, now = now),
               class = "namegender_webhook_error", regexp = "does not match")
})

test_that("a wrong secret is rejected", {
  expect_error(ng_webhook_verify(body, header, "whsec_other", now = now),
               class = "namegender_webhook_error", regexp = "does not match")
})

test_that("a stale timestamp is rejected", {
  expect_error(ng_webhook_verify(body, header, secret, now = now + 301),
               class = "namegender_webhook_error", regexp = "tolerance")
  expect_equal(ng_webhook_verify(body, header, secret, now = now + 300)$id, "evt_1")
})

test_that("a missing header is rejected", {
  expect_error(ng_webhook_verify(body, NULL, secret, now = now), class = "namegender_webhook_error", regexp = "Missing")
  expect_error(ng_webhook_verify(body, "", secret, now = now), class = "namegender_webhook_error", regexp = "Missing")
})

test_that("a malformed header is rejected", {
  expect_error(ng_webhook_verify(body, "t=abc,v1=", secret, now = now),
               class = "namegender_webhook_error", regexp = "Malformed")
})

test_that("a webhook error is also a namegender_error", {
  expect_error(ng_webhook_verify(body, "t=abc,v1=", secret, now = now), class = "namegender_error")
})
