#' Builds an events_tbl table
#'
#' The eeg_lst `events` table is organised into columns representing the `.type` of event
#' associated with the trigger listed under `.description`. The timestamp marking
#' the beginning and the end of the event is listed under `.initial` and `.final` (in samples).
#' The `.channel` column is a
#' linking variable only, so will generally only contain NAs, unless the
#' event is specific to a certain channel.
#'
#' @param .id Integers indicating to which group the row of the signal matrix belongs.
#' @param .initial Vector of integers that indicate at which sample an events starts.
#' @param .final Vector of integers that indicate at which sample an events ends.
#' @param .channel Vector of characters that indicate to which channel the event is relevant or NA for all the channels.
#'
#' @family events_tbl
#'
#' @return A valid `events_tbl` table.
#' @noRd
new_events_tbl <- function(.id = integer(0),
                           .type =  character(0),
                           .description =  character(0),
                           .initial = sample_int(integer(0), integer(0)),
                           .final = sample_int(integer(0), integer(0)),
                           .channel = character(0),
                           sampling_rate = NULL) {
  # If there is something, but incomplete, fill with NAs the columns that might be empty
  if (length(.id) != 0) {
    if (length(.channel) == 0) .channel <- NA_character_
    if (length(.type) == 0) .type <- NA_character_
    if (length(.description) == 0) .type <- NA_character_
  } 
    events <- data.table::data.table(
    .id = .id,
    .type =  .type,
    .description =  .description,
    .initial = .initial,
    .final = .final,
    .channel = .channel
  )

  if (!is.null(sampling_rate)) {
    events[, .initial := sample_int(as.integer(.initial),
      sampling_rate = sampling_rate)
      ]
    events[, .final := sample_int(as.integer(.final),
      sampling_rate = sampling_rate)
      ]
  }
  data.table::setattr(events, "class", c("events_tbl", class(events)))
  events[]
}
as_events_tbl <- function(.data, ...) {
  UseMethod("as_events_tbl")
}

as_events_tbl.data.table <- function(.data, sampling_rate = NULL) {
  .data <- data.table::copy(.data)
  .data[, .id := as.integer(.id)]
  if (!is.null(sampling_rate)) {
    .data[, .initial := sample_int(as.integer(.initial),
      sampling_rate = sampling_rate
    )]
    .data[, .final := sample_int(as.integer(.final),
      sampling_rate = sampling_rate
    )]
  }
  .data <- .data %>% dplyr::select(
    .id, setdiff(colnames(.data), obligatory_cols[[".events"]]),
    obligatory_cols[[".events"]][-1]
  )
  data.table::setattr(.data, "class", c("events_tbl", class(.data)))
  validate_events_tbl(.data)
}

as_events_tbl.events_tbl <- function(.data, sampling_rate = NULL) {
  if (!is.null(sampling_rate)) {
    .data <- data.table::copy(.data)
    .data[, .initial := sample_int(as.integer(.initial),
      sampling_rate = sampling_rate
    )]
    .data[, .final := sample_int(as.integer(.final),
      sampling_rate = sampling_rate
    )]
  }
  validate_events_tbl(.data)
}


as_events_tbl.data.frame <- function(.data, sampling_rate = NULL) {
  .data <- data.table::as.data.table(.data)
  as_events_tbl(.data, sampling_rate = sampling_rate)
}

#' @noRd
as_events_tbl.NULL <- function(.data, sampling_rate = NULL) {
  new_events_tbl(sampling_rate = sampling_rate)
}

#' Test if the object is an events_tbl
#' This function returns  TRUE for events_tbl.
#'
#' @param x An object.
#'
#' @family events_tbl
#'
#' @return `TRUE` if the object inherits from the `events_tbl` class.
is_events_tbl <- function(x) {
  "events_tbl" %in% class(x)
}

#' @param events
#'
#' @param channels
#'
#' @noRd
validate_events_tbl <- function(events) {
  if (!is_events_tbl(events)) {
    warning("Class is not events_tbl", call. = FALSE)
  }
  if(!all(obligatory_cols[[".events"]] %in% colnames(events))) {
    warning("Missing tables in the events table, some functions may not work correctly", call. = FALSE)
  }
  if (!data.table::is.data.table(events)) {
    warning("'events' should be a data.table.",
      call. = FALSE
    )
  }

  if (!is_sample_int(events$.initial)) {
    warning("Values of .initial should be samples",
      call. = FALSE
    )
  }
  if (!is.character(events$.channel)) {
    warning("Values of .channel should be characters (or NA_chararacter_)",
            call. = FALSE
    )
  }
  if (!is_sample_int(events$.final)) {
    warning("Values of .final should be samples",
      call. = FALSE
    )
  }
  if (is.numeric(events$.initial) && is.numeric(events$.final) &&
      any(events$.final < events$.initial)) {
    warning("Values of .final should be larger than values of .initial",
      call. = FALSE
    )
  }

  events[]
}


filter.events_tbl <- function(.data, ..., preserve = FALSE) {
  as_events_tbl(NextMethod(), sampling_rate(.data))
}
mutate.events_tbl <- function(.data, ...) {
  as_events_tbl(NextMethod(), sampling_rate(.data))
}
transmute.events_tbl <- function(.data, ...) {
  as_events_tbl(NextMethod(), sampling_rate(.data))
}
summarise.events_tbl <- function(.data, ...) {
  as_events_tbl(NextMethod(), sampling_rate(.data))
}
