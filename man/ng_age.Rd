\name{ng_age}
\alias{ng_age}
\alias{ng_age_bulk}
\title{Age from a first name}
\description{
How old the people recorded with a first name are: the median age, the middle
half and the middle 80\% of their ages. One credit per name.

The age describes a group, not a person: never use it for decisions about an
individual. It covers the United States, France and Norway. For another country
\code{age} is \code{NULL} and \code{reason} is \code{"country_not_covered"}, and
no credit is charged. Without a country hint the US data is used and
\code{country_source} is \code{"default"}. A missing age is an answer, not an
error.
}
\usage{
ng_age(client, name, gender = NULL, country = NULL, locale = NULL, ip = NULL)

ng_age_bulk(client, names, gender = NULL, country = NULL, locale = NULL, ip = NULL)
}
\arguments{
  \item{client}{A client returned by \code{\link{namegender}()}.}
  \item{name}{A first or full name (\code{"Brittany"}).}
  \item{names}{A character vector of 1 to 100 names. The other arguments apply to every name.}
  \item{gender}{Optional \code{"male"} or \code{"female"}: use only that gender's records.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code whose records are used.}
  \item{locale}{Optional language tag such as \code{"fr-FR"}, a country hint.}
  \item{ip}{Optional IP address of your end user, a country hint. Not stored by the API.}
}
\value{
The parsed API response. \code{ng_age()} returns \code{name}, \code{first_name},
\code{gender}, \code{age} (the median age), \code{age_range} (\code{low} and
\code{high} of the middle half), \code{age_range_80} (the middle 80\%),
\code{birth_year}, \code{sample_size}, \code{births}, \code{country},
\code{country_source} (\code{"country"}, \code{"locale"}, \code{"ip"} or
\code{"default"}), \code{source}, \code{series}, \code{reference_year} and
\code{reason}, alongside \code{credits_charged}, \code{credits_remaining} and
\code{request_id}. \code{age}, \code{age_range}, \code{age_range_80},
\code{birth_year}, \code{first_name}, \code{source}, \code{series} and
\code{gender} can be \code{NULL}. When \code{age} is \code{NULL}, \code{reason}
is \code{"not_found"}, \code{"insufficient_data"} or
\code{"country_not_covered"}.

\code{ng_age_bulk()} returns \code{results}, a data frame with one row per name
in input order and the same fields from \code{name} to \code{reason}
(\code{age_range} and \code{age_range_80} are nested data frames; missing
values are \code{NA}); the credit fields and \code{country_source} are on the
envelope.

A non-2xx response is raised as a \code{namegender_error} condition.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
brittany <- ng_age(client, "Brittany")
brittany$age         # 36
brittany$age_range   # low 32, high 38
ng_age(client, "Jordan", gender = "female", country = "US")$age
bulk <- ng_age_bulk(client, c("Brittany", "Margaret"), country = "US")
bulk$results[, c("name", "age", "birth_year")]
}
}
