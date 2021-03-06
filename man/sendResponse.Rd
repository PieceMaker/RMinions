% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sendResponse.R
\name{sendResponse}
\alias{sendResponse}
\title{A function that takes a connection, a location, a status, and a response and send the response.}
\usage{
sendResponse(conn, queue, status = c("succeeded", "failed",
  "catastrophic"), job, response, useJSON = F)
}
\arguments{
\item{conn}{An open redux hiredis connection.}

\item{queue}{A string giving the name of the queue where the response will be sent.}

\item{status}{One of the following strings: "succeeded", "failed", or "catastrophic".}

\item{job}{The job that was used to generate `result`.}

\item{response}{The result of executing the job.}

\item{useJSON}{Flag specifying whether messages are in JSON format. Defaults to false.}
}
\description{
\code{sendResponse} takes the required inputs for a response, formats them appropriately, and
then sends the response.
}
\details{
The response that will be sent back is the original `job` with the addition of the `status`
property and one of the following two properties: `error` or `results`. If `status` is either
'failed' or 'catastrophic', then `response` will be placed in the `error` property. If `status`
is 'succeeded' then `response` will be placed in the `response` property.

The 'failed' status should be used when the error occurred while executing the job and was
handled. The 'catastrophic' status should be used whenever an unhandled error that trips the
final try-catch occurs.
}
