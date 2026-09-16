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
  \item{...}{Additional API options such as \code{askToAI}.}
}
\value{
\code{namegender()} returns a client object. Lookup functions return the parsed API response.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_name(client, "Ayse", country = "TR")
ng_countries(client, "Mehmet", limit = 10)
}
}
