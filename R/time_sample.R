#' Convert a sample point into a time point.
#'
#'
#' @param x A `sample_id` object.
#' @param unit "seconds" (or "s"), "milliseconds" (or "ms")
#'
#' @return A vector of times.
#'
#'
#' @export
as_time <- function(x, unit = "second") {
  UseMethod("as_time")
}

#' @export
as_time.sample_int <- function(x, unit = "second") {
  time <- (x - 1) / scaling(sampling_rate = attributes(x)$sampling_rate, unit)
  attributes(time) <- NULL
  time
}
#' @export
as_time.default <- function(x, unit = "second") {
  stop("`as_time()` can only be used with samples. Tip: You should probably use it with `.sample`.")
}

#' Convert a time point  into a sample.
#'
#'
#'
#' @return A sample_int object.
#' @param ... Not in use.
#' @export
as_sample_int <- function(x, ...) {
  UseMethod("as_sample_int")
}
#' @rdname as_sample_int
#' @param x A vector of numeric values.
#' @param unit "seconds" (or "s"), "milliseconds" (or "ms"), or "samples"
#' @param sampling_rate Sampling rate in Hz
#' @export
as_sample_int.numeric <- function(x, sampling_rate = NULL, unit = "s", ...) {
  if (is.null(sampling_rate)) stop("'sampling_rate' needs to be specified", call. = FALSE)
  scale <- scaling(sampling_rate, unit = unit)
  # shift if it's in time scale so that sample 1 corresponds to time 0,
  # but not shift if it's converting samples into samples
  shift <- if(scale == 1) 0 else 1
  samples <- round(x * scale + shift) 
  sample_int(samples, sampling_rate)
}
#' @export
as_sample_int.sample_int <- function(x, ...) {
  x
}
