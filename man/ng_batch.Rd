\name{ng_batch}
\alias{ng_batch}
\alias{ng_batch_create}
\alias{ng_batch_start}
\alias{ng_batch_get}
\alias{ng_batch_list}
\alias{ng_batch_cancel}
\alias{ng_batch_wait}
\alias{ng_batch_download}
\title{File Jobs}
\description{
Upload a CSV or XLSX file (up to 100 MB and 1,000,000 rows) and get it back
with gender columns added. One credit per row, charged only if the job
completes.

\code{name_column} is required to start: a guessed column that turns out to be
wrong would spend credits on the wrong data. To see the columns and the cost
first, upload with \code{start = FALSE}, read \code{job$inspection}, then call
\code{ng_batch_start()}.

\code{ng_batch_create()} sends an \code{Idempotency-Key} and retries connection
errors and 502/503/504 with the same key (after 1 and then 2 seconds), so a
retry never opens a second job. Other errors, 4xx included, are not retried.
Pass your own \code{idempotency_key} to keep that guarantee across your own
retries.
}
\usage{
ng_batch_create(client, file, name_column = NULL, country_column = NULL,
  country = NULL, ai_fallback = NULL, best_guess = NULL,
  delete_after_download = NULL, start = TRUE, idempotency_key = NULL,
  retries = 2, filename = NULL, ...)

ng_batch_start(client, id, name_column, ...)

ng_batch_get(client, id)

ng_batch_list(client, limit = NULL, page = NULL)

ng_batch_cancel(client, id)

ng_batch_wait(client, id, timeout = 3600, on_progress = NULL)

ng_batch_download(client, id, path = NULL)
}
\arguments{
  \item{client}{A client returned by \code{namegender()}.}
  \item{file}{Path to a \code{.csv}, \code{.tsv} or \code{.xlsx} file with a header row, or a raw vector (then \code{filename} is required). The file name's extension tells the API the format.}
  \item{name_column}{Header of the column holding the names, exactly as written in the file. Required to start.}
  \item{country_column}{Optional header of a column holding a country code per row.}
  \item{country}{Optional default ISO 3166-1 alpha-2 country code for rows without one.}
  \item{ai_fallback}{\code{TRUE} asks a language model for names not in the database (needs AI consent on the account).}
  \item{best_guess}{\code{TRUE} returns the more likely gender even when the evidence is weak.}
  \item{delete_after_download}{\code{TRUE} lets the result be downloaded once, then deletes it.}
  \item{start}{\code{FALSE} uploads and inspects only; the job then carries \code{inspection} (columns, preview, cost).}
  \item{idempotency_key}{Optional key, up to 80 printable ASCII characters. One is generated per call when omitted.}
  \item{retries}{How many times to retry a connection error or a 502/503/504.}
  \item{filename}{File name to send, needed when \code{file} is a raw vector.}
  \item{id}{A job id, such as \code{"B-7K2M9QX4TA"}.}
  \item{limit, page}{Optional paging for \code{ng_batch_list()}.}
  \item{timeout}{Seconds to wait before giving up.}
  \item{on_progress}{Optional function called with the job after every poll.}
  \item{path}{Optional path to write the result file to.}
  \item{...}{Further settings sent as they are. Logical values are sent as \code{"true"} or \code{"false"}; \code{NULL} values are left out.}
}
\value{
\code{ng_batch_create()}, \code{ng_batch_start()}, \code{ng_batch_get()} and
\code{ng_batch_wait()} return the job as a list: \code{id}, \code{status}
(\code{uploaded}, \code{queued}, \code{processing}, \code{completed},
\code{failed} or \code{cancelled}), \code{progress}, \code{rows},
\code{credits}, \code{summary}, \code{error} and \code{poll_after_seconds},
among others. \code{ng_batch_list()} returns a page of jobs, newest first,
including jobs started from the dashboard.

\code{ng_batch_wait()} polls every \code{poll_after_seconds} (5 when absent)
until the job is completed, failed or cancelled (or still \code{uploaded}), and
returns it. A failed job is returned, not raised: check \code{status} and
\code{error$code}. Running past \code{timeout} is an error.

\code{ng_batch_cancel()} returns the credit of a job that has not started, and
deletes a finished one; it returns \code{NULL} invisibly.

\code{ng_batch_download()} returns the result file as a raw vector, or writes it
to \code{path} and returns \code{path} invisibly. The result appends
\code{gender}, \code{probability}, \code{sample_size}, \code{country},
\code{source}, \code{matched_as}, \code{first_name}, \code{middle_name},
\code{last_name} and \code{name_type} to every row. A CSV result starts with a
UTF-8 byte order mark; read it with \code{fileEncoding = "UTF-8-BOM"}.

A non-2xx response is raised as a condition of class \code{namegender_error}
carrying \code{status} and the API's \code{body}. Up to three jobs can be
queued or running at once; a fourth is refused with \code{429 too_many_batches}.
}
\examples{
\dontrun{
client <- namegender(Sys.getenv("NAMEGENDER_API_KEY"))
job <- ng_batch_create(client, "customers.csv",
  name_column = "first_name", country_column = "country")
done <- ng_batch_wait(client, job$id, on_progress = function(j) message(j$progress, "\%"))
if (done$status == "failed") stop(done$error$code)
ng_batch_download(client, done$id, "customers-gender.csv")
}
}
