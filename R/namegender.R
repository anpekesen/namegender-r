namegender <- function(api_key, base_url = "https://namegender.com/api/v1") {
  if (!nzchar(api_key)) stop("api_key is required", call. = FALSE)
  structure(list(api_key = api_key, base_url = sub("/$", "", base_url)), class = "namegender_client")
}

# Hatalar "namegender_error" sınıflı bir koşul olarak yükselir: status ve API
# gövdesi (error, message, request_id, docs) koşulun üzerinde taşınır, böylece
# tryCatch(..., namegender_error = ) mesaja değil e$body$error'a bakabilir.
ng_abort <- function(message, status = 0L, body = NULL, class = NULL) {
  stop(structure(
    class = c(class, "namegender_error", "error", "condition"),
    list(message = message, call = NULL, status = status, body = body)
  ))
}

ng_call <- function(client, path, method = "GET", json = NULL, raw = NULL, type = NULL, headers = list(), query = list()) {
  req <- httr2::request(paste0(client$base_url, path)) |>
    httr2::req_method(method) |>
    httr2::req_headers(Authorization = paste("Bearer", client$api_key), Accept = "application/json") |>
    httr2::req_error(is_error = function(resp) FALSE)
  if (length(headers)) req <- do.call(httr2::req_headers, c(list(req), headers))
  query <- compact(query)
  if (length(query)) req <- do.call(httr2::req_url_query, c(list(req), query))
  if (!is.null(json)) req <- httr2::req_body_json(req, json, auto_unbox = TRUE)
  if (!is.null(raw)) req <- httr2::req_body_raw(req, raw, type = type)
  response <- httr2::req_perform(req)
  if (httr2::resp_is_error(response)) {
    status <- httr2::resp_status(response)
    body <- tryCatch(ng_parse(response), error = function(e) NULL)
    message <- if (is.list(body)) body$message
    ng_abort(message %||% paste("HTTP", status), status = status, body = body)
  }
  response
}

# 204 (iptal edilen iş) gövdesizdir; ayrıştırmaya çalışmak hata verir.
ng_parse <- function(response) {
  if (!length(httr2::resp_body_raw(response))) return(NULL)
  httr2::resp_body_json(response, simplifyVector = TRUE)
}

ng_request <- function(client, path, body) ng_parse(ng_call(client, path, "POST", json = body))

`%||%` <- function(x, y) if (is.null(x)) y else x
compact <- function(x) x[!vapply(x, is.null, logical(1))]
# locale ve ip ülke ipucudur: öncelik country > locale > ip. Hangisinin
# kullanıldığı yanıtın country_source alanında döner (toplu istekte zarfta).
ng_name <- function(client, name, country = NULL, locale = NULL, ip = NULL, ...) ng_request(client, "/gender", compact(c(list(name=name, country=country, locale=locale, ip=ip), list(...))))
ng_email <- function(client, email, country = NULL, locale = NULL, ip = NULL, ...) ng_request(client, "/gender/email", compact(c(list(email=email, country=country, locale=locale, ip=ip), list(...))))
ng_username <- function(client, username, country = NULL, locale = NULL, ip = NULL, ...) ng_request(client, "/gender/username", compact(c(list(username=username, country=country, locale=locale, ip=ip), list(...))))
# names her zaman JSON dizisi olarak gider: auto_unbox tek elemanlı vektörü
# düz metne çevirir ve API tek isimli toplu isteği reddeder. as.character,
# data frame'den gelen faktör sütununu da isimlere çevirir.
ng_bulk <- function(client, names, country = NULL, type = "name", locale = NULL, ip = NULL, ...) ng_request(client, "/gender/bulk", compact(c(list(names=as.list(as.character(names)), country=country, type=type, locale=locale, ip=ip), list(...))))
ng_countries <- function(client, name, limit = NULL) ng_request(client, "/gender/countries", compact(list(name=name, limit=limit)))

# Hitap ------------------------------------------------------------------------

# Hitap uç noktası best_guess ve ai_fallback almaz; bu yüzden burada ... yok,
# yanlışlıkla verilen seçenek sessizce gitmek yerine R hatası verir.
# first_name ve last_name ayrı tutulan adlar içindir, API onları ayrıştırmaz.
ng_salutation <- function(client, name = NULL, language = NULL, country = NULL, locale = NULL, ip = NULL,
                          gender = NULL, min_probability = NULL, title = NULL, first_name = NULL, last_name = NULL) {
  ng_request(client, "/salutation", compact(list(
    name = name, first_name = first_name, last_name = last_name, language = language, country = country,
    locale = locale, ip = ip, gender = gender, min_probability = min_probability, title = title
  )))
}
# Seçenekler her isme uygulanır; results girdi sırasını korur.
ng_salutation_bulk <- function(client, names, language = NULL, country = NULL, locale = NULL, ip = NULL,
                               gender = NULL, min_probability = NULL, title = NULL) {
  ng_request(client, "/salutation/bulk", compact(list(
    names = as.list(as.character(names)), language = language, country = country, locale = locale, ip = ip,
    gender = gender, min_probability = min_probability, title = title
  )))
}

# İsim denetimi -----------------------------------------------------------------

# Formdaki bir adın gerçek bir kişi adına benzeyip benzemediğini gerekçeleriyle
# söyler; bir ada asla "sahte" demez. best_guess, ai_fallback ve language
# almaz; ... olmadığı için yanlışlıkla verilen seçenek R hatası verir.
# first_name ve last_name ayrı tutulan adlar içindir, API onları ayrıştırmaz.
ng_name_check <- function(client, name = NULL, country = NULL, locale = NULL, ip = NULL,
                          first_name = NULL, last_name = NULL) {
  ng_request(client, "/name-check", compact(list(
    name = name, first_name = first_name, last_name = last_name, country = country, locale = locale, ip = ip
  )))
}
# Seçenekler her isme uygulanır; results girdi sırasını korur.
ng_name_check_bulk <- function(client, names, country = NULL, locale = NULL, ip = NULL) {
  ng_request(client, "/name-check/bulk", compact(list(
    names = as.list(as.character(names)), country = country, locale = locale, ip = ip
  )))
}

# Yaş -------------------------------------------------------------------------

# Bir ilk adla kayıtlı kişilerin yaşı: medyan, ortadaki yarı ve ortadaki %80.
# Bir grubu anlatır, kişiyi değil. age boşken (tekilde NULL, toplu results'ta
# NA) reason dolar (not_found, insufficient_data, country_not_covered); bu
# hata değil, 200'dür.
# gender yalnızca "male" ya da "female" alır ve o cinsiyetin kayıtlarına daraltır.
ng_age <- function(client, name, gender = NULL, country = NULL, locale = NULL, ip = NULL) {
  ng_request(client, "/age", compact(list(
    name = name, gender = gender, country = country, locale = locale, ip = ip
  )))
}
# Seçenekler her isme uygulanır; results girdi sırasını korur.
ng_age_bulk <- function(client, names, gender = NULL, country = NULL, locale = NULL, ip = NULL) {
  ng_request(client, "/age/bulk", compact(list(
    names = as.list(as.character(names)), gender = gender, country = country, locale = locale, ip = ip
  )))
}

# Dosya işleri ----------------------------------------------------------------

# Yüklemeyi yeniden denemeye değer durumlar: istek uygulamaya hiç ulaşmamış
# olabilir. Geri kalanı (402, 422, 429 too_many_batches) aynı şekilde yine
# başarısız olur.
ng_retryable <- c(502L, 503L, 504L)
ng_finished <- c("completed", "failed", "cancelled")

# Testler beklemeyi bu bağlama üzerinden atlar.
ng_sleep <- function(seconds) Sys.sleep(seconds)

ng_batch_path <- function(id, suffix = "") paste0("/batches/", utils::URLencode(as.character(id), reserved = TRUE), suffix)

# Anahtar openssl'den gelir, sample()'dan değil: kullanıcının set.seed()'i iki
# ayrı yüklemeye aynı anahtarı verir ve ikincisi birincinin işini geri alırdı.
ng_idempotency_key <- function() paste(as.character(openssl::rand_bytes(16)), collapse = "")

ng_setting <- function(value) {
  if (is.logical(value)) if (isTRUE(value)) "true" else "false" else as.character(value)
}

ng_multipart <- function(fields, filename, content) {
  boundary <- paste(as.character(openssl::rand_bytes(16)), collapse = "")
  # Dosya adındaki tırnak ya da satır sonu başlığı erken bitirirdi.
  filename <- gsub("[\r\n]", "", gsub("\"", "%22", gsub("\\", "\\\\", filename, fixed = TRUE), fixed = TRUE))
  lines <- character()
  for (key in names(fields)) {
    lines <- c(lines, paste0("--", boundary), sprintf("Content-Disposition: form-data; name=\"%s\"", key), "", fields[[key]])
  }
  head <- paste(c(lines,
    paste0("--", boundary),
    sprintf("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"", filename),
    "Content-Type: application/octet-stream", "", ""), collapse = "\r\n")
  tail <- paste0("\r\n--", boundary, "--\r\n")
  list(
    body = c(charToRaw(enc2utf8(head)), content, charToRaw(tail)),
    type = paste0("multipart/form-data; boundary=", boundary)
  )
}

ng_batch_create <- function(client, file, name_column = NULL, country_column = NULL, country = NULL,
                            ai_fallback = NULL, best_guess = NULL, delete_after_download = NULL,
                            start = TRUE, idempotency_key = NULL, retries = 2, filename = NULL, ...) {
  if (is.raw(file)) {
    if (is.null(filename)) stop("filename is required when file is a raw vector", call. = FALSE)
    content <- file
  } else {
    path <- path.expand(file)
    content <- readBin(path, "raw", file.info(path)$size)
    filename <- filename %||% basename(path)
  }
  settings <- compact(c(list(
    name_column = name_column, country_column = country_column, country = country,
    ai_fallback = ai_fallback, best_guess = best_guess, delete_after_download = delete_after_download
  ), list(...)))
  fields <- c(list(start = ng_setting(isTRUE(start))), lapply(settings, ng_setting))
  body <- ng_multipart(fields, filename, content)
  # Her denemede aynı anahtar: bağlantı koptuktan sonraki tekrar ikinci bir iş
  # açıp krediyi iki kez ayırmak yerine ilk işi döndürür.
  headers <- list(`Idempotency-Key` = idempotency_key %||% ng_idempotency_key())

  attempt <- 0
  repeat {
    result <- tryCatch(
      ng_parse(ng_call(client, "/batches", "POST", raw = body$body, type = body$type, headers = headers)),
      error = function(e) e
    )
    if (!inherits(result, "error")) return(result)
    # namegender_error bir HTTP yanıtıdır; başka her hata bağlantı hatasıdır.
    retryable <- !inherits(result, "namegender_error") || result$status %in% ng_retryable
    if (!retryable || attempt >= retries) stop(result)
    ng_sleep(2^attempt)
    attempt <- attempt + 1
  }
}

ng_batch_start <- function(client, id, name_column, ...) {
  ng_request(client, ng_batch_path(id, "/start"), compact(c(list(name_column = name_column), list(...))))
}

ng_batch_get <- function(client, id) ng_parse(ng_call(client, ng_batch_path(id)))

ng_batch_list <- function(client, limit = NULL, page = NULL) {
  ng_parse(ng_call(client, "/batches", query = list(limit = limit, page = page)))
}

ng_batch_cancel <- function(client, id) {
  ng_call(client, ng_batch_path(id), "DELETE")
  invisible(NULL)
}

ng_batch_wait <- function(client, id, timeout = 3600, on_progress = NULL) {
  deadline <- proc.time()[["elapsed"]] + timeout
  repeat {
    job <- ng_batch_get(client, id)
    if (!is.null(on_progress)) on_progress(job)
    if (job$status %in% c(ng_finished, "uploaded")) return(job)
    pause <- job$poll_after_seconds
    if (is.null(pause) || !isTRUE(pause > 0)) pause <- 5
    if (proc.time()[["elapsed"]] + pause > deadline) {
      ng_abort(paste("Timed out waiting for", id), body = job)
    }
    ng_sleep(pause)
  }
}

ng_batch_download <- function(client, id, path = NULL) {
  content <- httr2::resp_body_raw(ng_call(client, ng_batch_path(id, "/result")))
  if (is.null(path)) return(content)
  writeBin(content, path)
  invisible(path)
}

# Webhook'lar ------------------------------------------------------------------

ng_webhook_fail <- function(message) ng_abort(message, class = "namegender_webhook_error")

# Sabit süreli karşılaştırma: == ilk farklı karakterde durur ve imzanın ne
# kadarının tuttuğunu zamanlamayla sızdırır. Uzunluk gizli değildir.
ng_equal <- function(a, b) {
  a <- utf8ToInt(a)
  b <- utf8ToInt(b)
  if (length(a) != length(b)) return(FALSE)
  sum(bitwXor(a, b)) == 0
}

ng_webhook_verify <- function(payload, signature_header, secret, tolerance = 300, now = NULL) {
  if (missing(secret) || is.null(secret) || !nzchar(secret)) stop("secret is required", call. = FALSE)
  if (is.null(signature_header) || length(signature_header) != 1 || is.na(signature_header) || !nzchar(signature_header)) {
    ng_webhook_fail("Missing NameGender-Signature header")
  }
  if (is.character(payload)) {
    payload <- charToRaw(enc2utf8(paste(payload, collapse = "")))
  } else if (!is.raw(payload)) {
    stop("payload must be the raw request body (a raw vector or a string)", call. = FALSE)
  }

  timestamp <- NULL
  signatures <- character()
  for (part in strsplit(signature_header, ",", fixed = TRUE)[[1]]) {
    part <- trimws(part)
    at <- regexpr("=", part, fixed = TRUE)
    if (at < 1) next
    key <- substr(part, 1, at - 1)
    value <- substr(part, at + 1, nchar(part))
    if (key == "t" && grepl("^[0-9]+$", value)) {
      timestamp <- as.numeric(value)
    } else if (key == "v1" && nzchar(value)) {
      signatures <- c(signatures, value)
    }
  }
  if (is.null(timestamp) || !length(signatures)) ng_webhook_fail("Malformed NameGender-Signature header")

  now <- now %||% as.numeric(Sys.time())
  if (abs(now - timestamp) > tolerance) ng_webhook_fail("Webhook timestamp is outside the tolerance window")

  signed <- c(charToRaw(paste0(sprintf("%.0f", timestamp), ".")), payload)
  expected <- paste(as.character(openssl::sha256(signed, key = charToRaw(enc2utf8(secret)))), collapse = "")
  # Her imza karşılaştırılır; ilk eşleşmede durmak da zamanlama farkı olurdu.
  matched <- vapply(signatures, function(signature) ng_equal(expected, signature), logical(1))
  if (!any(matched)) ng_webhook_fail("Webhook signature does not match")

  text <- rawToChar(payload)
  Encoding(text) <- "UTF-8"
  jsonlite::fromJSON(text, simplifyVector = TRUE)
}
