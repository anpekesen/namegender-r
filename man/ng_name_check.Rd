\name{ng_name_check}
\alias{ng_name_check}
\alias{ng_name_check_bulk}
\title{Name checks}
\description{
Whether a name typed into a form looks like a real person's name, with the
reasons. One credit per name.

It never calls a name fake: \code{assessment} is \code{"plausible"},
\code{"suspicious"} or \code{"implausible"}. Use it to flag records for a closer
look, not to reject people automatically. Surnames are judged by their shape
only. \code{best_guess}, \code{ai_fallback} and \code{language} do not apply and
are not accepted.
}
\usage{
ng_name_check(client, name = NULL, country = NULL, locale = NULL, ip = NULL,
  first_name = NULL, last_name = NULL)

ng_name_check_bulk(client, names, country = NULL, locale = NULL, ip = NULL)
}
\arguments{
  \item{client}{A client returned by \code{\link{namegender}()}.}
  \item{name}{The full name as typed (\code{"asdf qwerty"}), up to 200 characters.}
  \item{names}{A character vector of 1 to 100 full names. The other arguments apply to every name.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code.}
  \item{locale}{Optional language tag such as \code{"en-US"}, a country hint.}
  \item{ip}{Optional IP address of your end user, a country hint. Not stored by the API.}
  \item{first_name, last_name}{Use instead of \code{name} when they are stored separately,
    up to 100 characters each. They are taken as they are, not parsed.}
}
\value{
The parsed API response. \code{ng_name_check()} returns \code{query},
\code{assessment}, \code{score} (an integer from 0 to 100), \code{signals} (a
data frame with \code{code}, \code{severity}, \code{part} and \code{value};
\code{part} and \code{value} can be \code{NA}), \code{first_name},
\code{last_name}, \code{name_type} (\code{"personal"}, \code{"organization"} or
\code{"role"}) and \code{evidence} (\code{first_name_status}, which is
\code{"counted"}, \code{"attested"}, \code{"not_found"} or \code{NULL}, and
\code{first_name_counted_records}), alongside \code{credits_charged},
\code{credits_remaining}, \code{data_version}, \code{request_id} and
\code{country_source}.

Signal codes include \code{keyboard_pattern}, \code{repeated_characters},
\code{placeholder}, \code{fictional_character}, \code{contains_digits},
\code{organization_name}, \code{single_name}, \code{first_name_not_found} and
\code{first_name_attested}; severity is \code{high}, \code{medium}, \code{low},
\code{info} or \code{positive}.

\code{ng_name_check_bulk()} returns \code{summary} (\code{total}, \code{plausible},
\code{suspicious}, \code{implausible}) and \code{results}, a data frame with one
row per name in input order and the same fields from \code{query} to
\code{evidence}; the credit fields and \code{country_source} are on the envelope.

A non-2xx response is raised as a \code{namegender_error} condition.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_name_check(client, "asdf qwerty")$assessment     # "implausible"
ng_name_check(client, "Jennifer Null")$assessment   # "plausible"
ng_name_check(client, first_name = "Jennifer", last_name = "Null", country = "US")
bulk <- ng_name_check_bulk(client, c("Jennifer Null", "asdf qwerty"))
bulk$results[, c("query", "assessment", "score")]
}
}
