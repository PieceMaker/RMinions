#' A function that watches a message queue and starts working a job when one is available.
#'
#' \code{minionWorker} is a blocking function that will completely block the R instance
#' running it. It immediately performs some housekeeping by gathering logging information
#' and connecting to the message queue. Once connected, it performs a blocking pop on the
#' \code{jobsqueue} and waits until it receives a bundled job message. Once a message is
#' received, it runs the bundled function with the bundled parameters and stores any
#' returned results in the bundled response key.
#'
#' \code{minionWorker} is the core of the \code{redis-minions} package and multiple R
#' processes running this function should be spawned. The goal is to spawn just enough
#' workers that the full cpu resources of the system running them are maxed out when under
#' full jobs load. A good rule of thumb is that you should have \code{number of cores + 2}
#' workers running on a system.
#'
#' The minion worker is constructed to work with nearly all tasks. In order to accomplish
#' this, job messages need to be of a specific format. Job message must be lists with three
#' keys: \code{Function}, \code{Parameters}, \code{ResultsQueue}, and \code{ErrorQueue}.
#'
#' \code{Function} is the main function that controls the job and holds the core logic. Even
#' if the desired job is a simple script, the script should be wrapped in a function which
#' can then be passed to the worker. For more complex jobs that call subfunctions, it is
#' recommended that you create a package with these subfunctions and have \code{Function}
#' load this package. If \code{Function} must take input paremeters, define it as as a
#' function of one parameter (here referenced as \code{Parameters}), i.e.
#' \code{func(Parameters)}. Parameters will be a list and every desired parameter will be
#' a key.
#'
#' \code{Parameters} is a list of all the parameters to be passed to \code{Function}.
#'
#' \code{ResultsQueue} will be a string with the name of the redis queue to store any
#' returned results in.
#'
#' \code{ErrorQueue} will be a string with the name of the redis queue to store any errors
#' thrown while running the job.
#'
#' @export
#'
#' @param host The name or ip address of the redis server.
#' @param port The port the redis server is running on.
#' @param jobsQueue A string giving the name of the queue where jobs will be placed.
#'   Defaults to \code{jobsqueue}.
#' @param logging A boolean to enable or disable logging to a file on the system. Defaults
#'   to \code{true}.
#' @param logFileDir A string giving the directory to store worker log files if logging is
#'   enabled.

minionWorker <- function(host, port, jobsQueue = "jobsqueue", logging = T, logFileDir = "/var/log/R/") {
    workerHost <- as.character(System$getHostname())
    workerID <- paste0(host,'-worker-', Sys.getpid())
    if(logging) {
        logFilePath <- paste0(logFileDir, workerid, '.log')
        logFile <- file(logFilePath, open = 'a')
        sink(logFile, type = 'message')
    }

    conn <- redisConnect(host = host, port = port, returnRef = T)

    while(1) {

        job <- redisBRPopLPush(jobsQueue, workerID)

        func <- job$Function
        params <- job$Parameters
        #Pass in redis connection in case it is needed inside func
        params$redisConn <- conn
        resultsQueue <- job$ResultsQueue
        errorQueue <- job$ErrorQueue

        tryCatch(
            results <- func(params)
            redisRPush(resultsQueue, results),
            error = function(e) {
                redisRPush(errorQueue, e)
            },
            finally = redisDelete(workerid)
        )
    }
}