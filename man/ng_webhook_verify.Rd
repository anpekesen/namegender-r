\name{ng_webhook_verify}
\alias{ng_webhook_verify}
\title{Verify a NameGender Webhook}
\description{
Check the \code{NameGender-Signature} header of a webhook request and return
the parsed event.

Pass the body exactly as received. Parsing the JSON and serialising it again
changes the bytes, and the signature no longer matches. During a secret
rotation the header carries two \code{v1} values; either one matching is enough.
}
\usage{
ng_webhook_verify(payload, signature_header, secret, tolerance = 300, now = NULL)
}
\arguments{
  \item{payload}{The raw request body, as a raw vector or a string (read as UTF-8).}
  \item{signature_header}{The value of the \code{NameGender-Signature} header, \code{t=<unix seconds>,v1=<hex>}.}
  \item{secret}{The endpoint's signing secret from the dashboard.}
  \item{tolerance}{Seconds the timestamp may differ from the clock.}
  \item{now}{Optional current time in Unix seconds, for tests.}
}
\value{
The event as a list: \code{id}, \code{type} (\code{batch.completed},
\code{batch.failed}, \code{credits.low}, \code{credits.depleted} or
\code{webhook.test}), \code{created_at}, \code{api_version} and \code{data}.
For a batch event \code{data$object} is the job, as \code{ng_batch_get()}
returns it.

A missing or malformed header, a timestamp outside the tolerance window, or a
signature that does not match is raised as a condition of class
\code{namegender_webhook_error} (also a \code{namegender_error}). Answer such a
request with 400.
}
\examples{
event <- ng_webhook_verify(
  '{"id":"evt_1","type":"webhook.test"}',
  "t=1700000000,v1=857fcddfea47617c448b7a8e6537bbd59c9922a37c5273b2709812fbadb29e50",
  "whsec_test_vector",
  now = 1700000000
)
event$type
}
