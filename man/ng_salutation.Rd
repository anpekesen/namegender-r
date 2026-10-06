\name{ng_salutation}
\alias{ng_salutation}
\alias{ng_salutation_bulk}
\title{Salutations}
\description{
A ready-to-use salutation for a letter or an email, such as
\code{"Sehr geehrte Frau Dr. Müller,"} or \code{"Sayın Ahmet Bey,"}.
One credit per name.

When the gender is not certain enough (\code{min_probability}), the neutral
form is returned rather than a guess: \code{form} is \code{"gendered"},
\code{"neutral"} or \code{"organization"}, and \code{reason} says why a form is
not gendered. \code{best_guess} and \code{ai_fallback} do not apply and are not
accepted.
}
\usage{
ng_salutation(client, name = NULL, language = NULL, country = NULL,
  locale = NULL, ip = NULL, gender = NULL, min_probability = NULL,
  title = NULL, first_name = NULL, last_name = NULL)

ng_salutation_bulk(client, names, language = NULL, country = NULL,
  locale = NULL, ip = NULL, gender = NULL, min_probability = NULL,
  title = NULL)
}
\arguments{
  \item{client}{A client returned by \code{\link{namegender}()}.}
  \item{name}{The full name, titles included (\code{"Dr. Anna Müller"}), up to 200 characters.}
  \item{names}{A character vector of 1 to 100 full names. The other arguments apply to every name.}
  \item{language}{Language of the salutation: \code{en}, \code{en-US}, \code{en-GB}, \code{de},
    \code{de-AT}, \code{de-CH}, \code{fr}, \code{es}, \code{it}, \code{pt}, \code{pt-PT},
    \code{pt-BR}, \code{nl}, \code{tr}, \code{pl} or \code{ja}. Without it, the language of
    \code{locale}, then the main language of the country, then English. Any other value is a
    422 error.}
  \item{country}{Optional ISO 3166-1 alpha-2 country code, a hint for the gender lookup.}
  \item{locale}{Optional language tag such as \code{"de-AT"}: a country hint, and the default language.}
  \item{ip}{Optional IP address of your end user, a country hint. Not stored by the API.}
  \item{gender}{A known gender, \code{"male"}, \code{"female"} or \code{"neutral"}; skips the
    lookup. \code{"neutral"} always gives the neutral form.}
  \item{min_probability}{Certainty, 50 to 100, below which the neutral form is used. The server default is 90.}
  \item{title}{An academic title kept in a separate field, such as \code{"Dr."}. Used in German and English.}
  \item{first_name, last_name}{Use instead of \code{name} when they are stored separately.
    They are taken as they are, not parsed.}
}
\value{
The parsed API response. \code{ng_salutation()} returns \code{query}, \code{language},
\code{form}, \code{reason}, \code{salutation} (\code{formal}, \code{informal},
\code{neutral}), \code{parts} (\code{opening}, \code{courtesy}, \code{academic},
\code{name}, each possibly \code{NULL}), \code{gender}, \code{gender_source},
\code{probability}, \code{confidence}, \code{first_name}, \code{last_name},
\code{name_type} and \code{country}, alongside \code{credits_charged},
\code{credits_remaining}, \code{data_version}, \code{request_id} and
\code{country_source}.

\code{ng_salutation_bulk()} returns \code{summary} (\code{total}, \code{gendered},
\code{neutral}, \code{organization}) and \code{results}, a data frame with one row
per name in input order and the same fields from \code{query} to \code{country};
the credit fields, \code{language} and \code{country_source} are on the envelope.

A non-2xx response is raised as a \code{namegender_error} condition. For an
unsupported language its \code{status} is 422 and \code{body$supported} lists
the supported languages.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
ng_salutation(client, "Dr. Anna Müller", language = "de")$salutation$formal
ng_salutation(client, "Ahmet Yılmaz", language = "tr")$salutation$formal
ng_salutation(client, first_name = "Anna", last_name = "Müller", title = "Dr.", language = "de")
bulk <- ng_salutation_bulk(client, c("Dr. Anna Müller", "Müller GmbH"), language = "de")
bulk$results$salutation$formal
}
}
