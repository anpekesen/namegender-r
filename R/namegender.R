namegender <- function(api_key, base_url = "https://namegender.com/api/v1") {
  if (!nzchar(api_key)) stop("api_key is required", call. = FALSE)
  structure(list(api_key = api_key, base_url = sub("/$", "", base_url)), class = "namegender_client")
}

ng_request <- function(client, path, body) {
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
ng_name <- function(client, name, country = NULL, ...) ng_request(client, "/gender", compact(c(list(name=name, country=country), list(...))))
ng_email <- function(client, email, country = NULL, ...) ng_request(client, "/gender/email", compact(c(list(email=email, country=country), list(...))))
ng_username <- function(client, username, country = NULL, ...) ng_request(client, "/gender/username", compact(c(list(username=username, country=country), list(...))))
# names her zaman JSON dizisi olarak gider: auto_unbox tek elemanlı vektörü
# düz metne çevirir ve API tek isimli toplu isteği reddeder. as.character,
# data frame'den gelen faktör sütununu da isimlere çevirir.
ng_bulk <- function(client, names, country = NULL, type = "name", ...) ng_request(client, "/gender/bulk", compact(c(list(names=as.list(as.character(names)), country=country, type=type), list(...))))
ng_countries <- function(client, name, limit = NULL) ng_request(client, "/gender/countries", compact(list(name=name, limit=limit)))
