\name{namegender}
\alias{namegender}
\alias{ng_name}
\alias{ng_email}
\alias{ng_username}
\alias{ng_bulk}
\alias{ng_countries}
\title{NameGender API Client}
\description{
Create a NameGender client and resolve names, email addresses, usernames, or batches.
For files, see \code{\link{ng_batch}}; for webhooks, \code{\link{ng_webhook_verify}}.

\code{ng_countries()} returns the countries a name is recorded in. It is not a
country-of-origin or ethnicity inference: \code{registrations} is counted volume,
comparable only among the countries that publish counted birth statistics, and
\code{attested_in} is presence with no weight attached. Show \code{basis$note}
next to any percentage.
}
\usage{
namegender(api_key, base_url = "https://namegender.com/api/v1")

ng_name(client, name, country = NULL, locale = NULL, ip = NULL, ...)

ng_email(client, email, country = NULL, locale = NULL, ip = NULL, ...)

ng_username(client, username, country = NULL, locale = NULL, ip = NULL, ...)

ng_bulk(client, names, country = NULL, type = "name",
  locale = NULL, ip = NULL, ...)

ng_countries(client, name, limit = NULL)
}
\arguments{
  \item{api_key}{A NameGender API key.}
  \item{base_url}{API base URL.}
  \item{client}{A client returned by \code{namegender()}.}
  \item{name}{A first or full name. For \code{ng_countries()}, the first name to look up.}
  \item{email}{An email address.}
  \item{username}{A username or handle.}
  \item{names}{A character vector of inputs.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code.}
  \item{type}{Bulk input type: \code{name}, \code{email}, or \code{username}.}
  \item{locale}{Optional language tag such as \code{"it-IT"} or \code{"pt_BR"} (up to 35 characters). Its region is used as the country when \code{country} is not given; a tag without a region, such as \code{"en"}, sets no country.}
  \item{ip}{Optional IP address of your end user (up to 45 characters). Its country is used when neither \code{country} nor a regional \code{locale} is given. The API does not store it.}
  \item{limit}{Optional number of counted countries to return in \code{registrations}, 1 to 100. The server default is 25.}
  \item{...}{Additional API options: \code{ai_fallback = TRUE} falls back to a language model for names not in the database (needs AI consent on the account); \code{best_guess = TRUE} returns the most likely gender even below the probability threshold.}
}
\value{
\code{namegender()} returns a client object. Lookup functions return the parsed API response.
A lookup result has \code{query}, \code{name}, \code{first_name}, \code{middle_name}, \code{last_name}, \code{name_type}, \code{gender}, \code{country},
\code{probability}, \code{sample_size}, \code{took_ms}, \code{source},
\code{confidence} and \code{matched_as}, alongside \code{credits_charged},
\code{credits_remaining}, \code{data_version}, \code{request_id} and \code{country_source}.
\code{country_source} says which input set the country: \code{"country"},
\code{"locale"} or \code{"ip"}, or \code{NULL} when none did (the priority is
\code{country} > \code{locale} > \code{ip}). For \code{ng_bulk()} it is on the
response envelope, next to \code{took_ms}, not on each row of \code{results}. A non-2xx
response is raised as an error carrying the API's \code{message}; its class is
\code{namegender_error}, with \code{status} and the API's \code{body} on the condition.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_name(client, "Ayse", country = "TR")
ng_name(client, "Andrea", country = "IT", best_guess = TRUE)
ng_name(client, "Andrea", locale = "it-IT", ip = "203.0.113.7")
ng_countries(client, "Mehmet", limit = 10)
}
}
