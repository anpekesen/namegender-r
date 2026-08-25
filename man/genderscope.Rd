\name{genderscope}
\alias{genderscope}
\alias{gs_name}
\alias{gs_email}
\alias{gs_username}
\alias{gs_bulk}
\title{GenderScope API Client}
\description{
Create a GenderScope client and resolve names, email addresses, usernames, or batches.
}
\usage{
genderscope(api_key, base_url = "https://genderscope.io/api/v1")

gs_name(client, name, country = NULL, ...)

gs_email(client, email, country = NULL, ...)

gs_username(client, username, country = NULL, ...)

gs_bulk(client, names, country = NULL, type = "name", ...)
}
\arguments{
  \item{api_key}{A GenderScope API key.}
  \item{base_url}{API base URL.}
  \item{client}{A client returned by \code{genderscope()}.}
  \item{name}{A first or full name.}
  \item{email}{An email address.}
  \item{username}{A username or handle.}
  \item{names}{A character vector of inputs.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code.}
  \item{type}{Bulk input type: \code{name}, \code{email}, or \code{username}.}
  \item{...}{Additional API options such as \code{askToAI}.}
}
\value{
\code{genderscope()} returns a client object. Lookup functions return the parsed API response.
}
\examples{
\dontrun{
client <- genderscope(Sys.getenv("GENDERSCOPE_API_KEY"))
gs_name(client, "Ayse", country = "TR")
}
}
