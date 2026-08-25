genderscope <- function(api_key, base_url = "https://genderscope.io/api/v1") {
  if (!nzchar(api_key)) stop("api_key is required", call. = FALSE)
  structure(list(api_key = api_key, base_url = sub("/$", "", base_url)), class = "genderscope_client")
}

gs_request <- function(client, path, body) {
  response <- httr2::request(paste0(client$base_url, path)) |>
    httr2::req_headers(Authorization = paste("Bearer", client$api_key), Accept = "application/json") |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()
  parsed <- httr2::resp_body_json(response, simplifyVector = TRUE)
  if (httr2::resp_is_error(response)) stop(parsed$message %||% paste("HTTP", httr2::resp_status(response)), call. = FALSE)
  parsed
}

`%||%` <- function(x, y) if (is.null(x)) y else x
compact <- function(x) x[!vapply(x, is.null, logical(1))]
gs_name <- function(client, name, country = NULL, ...) gs_request(client, "/gender", compact(c(list(name=name, country=country), list(...))))
gs_email <- function(client, email, country = NULL, ...) gs_request(client, "/gender/email", compact(c(list(email=email, country=country), list(...))))
gs_username <- function(client, username, country = NULL, ...) gs_request(client, "/gender/username", compact(c(list(username=username, country=country), list(...))))
gs_bulk <- function(client, names, country = NULL, type = "name", ...) gs_request(client, "/gender/bulk", compact(c(list(names=names, country=country, type=type), list(...))))
