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

\code{ng_countries()} returns the countries a name is recorded in. It is not a
country-of-origin or ethnicity inference: \code{registrations} is counted volume,
comparable only among the countries that publish counted birth statistics, and
\code{attested_in} is presence with no weight attached. Show \code{basis$note}
next to any percentage.
}
\usage{
namegender(api_key, base_url = "https://namegender.com/api/v1")

ng_name(client, name, country = NULL, ...)

ng_email(client, email, country = NULL, ...)

ng_username(client, username, country = NULL, ...)

ng_bulk(client, names, country = NULL, type = "name", ...)

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
  \item{limit}{Optional number of counted countries to return in \code{registrations}, 1 to 100. The server default is 25.}
  \item{...}{Additional API options: \code{ai_fallback = TRUE} falls back to a language model for names not in the database (needs AI consent on the account); \code{best_guess = TRUE} returns the most likely gender even below the probability threshold.}
}
\value{
\code{namegender()} returns a client object. Lookup functions return the parsed API response.
A lookup result has \code{query}, \code{name}, \code{gender}, \code{country},
\code{probability}, \code{sample_size}, \code{took_ms}, \code{source},
\code{confidence} and \code{matched_as}, alongside \code{credits_charged},
\code{credits_remaining}, \code{data_version} and \code{request_id}. A non-2xx
response is raised as an error carrying the API's \code{message}.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_name(client, "Ayse", country = "TR")
ng_name(client, "Andrea", country = "IT", best_guess = TRUE)
ng_countries(client, "Mehmet", limit = 10)
}
}
