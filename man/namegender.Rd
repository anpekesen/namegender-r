\name{namegender}
\alias{namegender}
\alias{ng_name}
\alias{ng_email}
\alias{ng_username}
\alias{ng_bulk}
\title{NameGender API Client}
\description{
Create a NameGender client and resolve names, email addresses, usernames, or batches.
}
\usage{
namegender(api_key, base_url = "https://namegender.com/api/v1")

ng_name(client, name, country = NULL, ...)

ng_email(client, email, country = NULL, ...)

ng_username(client, username, country = NULL, ...)

ng_bulk(client, names, country = NULL, type = "name", ...)
}
\arguments{
  \item{api_key}{A NameGender API key.}
  \item{base_url}{API base URL.}
  \item{client}{A client returned by \code{namegender()}.}
  \item{name}{A first or full name.}
  \item{email}{An email address.}
  \item{username}{A username or handle.}
  \item{names}{A character vector of inputs.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code.}
  \item{type}{Bulk input type: \code{name}, \code{email}, or \code{username}.}
  \item{...}{Additional API options such as \code{askToAI}.}
}
\value{
\code{namegender()} returns a client object. Lookup functions return the parsed API response.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_name(client, "Ayse", country = "TR")
}
}
