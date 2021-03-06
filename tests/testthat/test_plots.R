context("test eeguana plotting functions")
library(eeguana)


# create fake dataset
data_1 <- eeg_lst(
  signal_tbl = dplyr::tibble(
    X = sin(1:30),
    Y = sin(1:30),
    .id = rep(c(1L, 2L, 3L), each = 10),
    .sample = sample_int(rep(seq(-4L, 5L), times = 3), sampling_rate = 500)
  ),
  channels_tbl = dplyr::tibble(
    .channel = c("X", "Y"), .reference = NA, theta = NA, phi = NA,
    radius = NA, .x = c(1, -10), .y = c(1, 1), .z = c(1, 10)
  ),
  events_tbl = dplyr::tribble(
    ~.id, ~.type, ~.description, ~.initial, ~.final, ~.channel,
    1L, "New Segment", NA_character_, -4L, -4L, NA,
    1L, "Bad", NA_character_, -2L, 0L, NA,
    1L, "Time 0", NA_character_, 1L, 1L, NA,
    1L, "Bad", NA_character_, 2L, 3L, "X",
    2L, "New Segment", NA_character_, -4L, -4L, NA,
    2L, "Time 0", NA_character_, 1L, 1L, NA,
    2L, "Bad", NA_character_, 2L, 2L, "Y",
    3L, "New Segment", NA_character_, -4L, -4L, NA,
    3L, "Time 0", NA_character_, 1L, 1L, NA,
    3L, "Bad", NA_character_, 2L, 2L, "Y"
  ),
  segments_tbl = dplyr::tibble(
    .id = c(1L, 2L, 3L),
    .recording = "recording1",
    segment = c(1L, 2L, 3L),
    condition = c("a", "b", "a")
  )
)


data("data_faces_ERPs")
data("data_faces_10_trials")


# helper functions (borrowed from github.com/stan-dev/bayesplot/R/helpers-testthat.R)
expect_gg <- function(x) {
  testthat::expect_s3_class(x, "ggplot")
  invisible(ggplot2::ggplot_build(x))
}

# if eeguana plots were not classed as ggplot2::ggplot, could use something like this:
# expect_eeguanaplot <- function(x) testthat::expect_s3_class(x, "eeguanaplot")

## auto plot
plot <- plot(data_faces_ERPs)

# create line plot
smaller_data <- data_faces_ERPs %>%
  dplyr::select(Fp1, Fpz, Fp2)
lineplot_eeg <- smaller_data %>%
  ggplot2::ggplot(ggplot2::aes(x = .time, y = .value)) +
  ggplot2::geom_line(ggplot2::aes(group = .id, colour = condition), alpha = .5) +
  ggplot2::stat_summary(
    fun = "mean", geom = "line",
    ggplot2::aes(colour = condition), alpha = 1, size = 1
  ) +
  # only .key works dynamically but only channel works with test()!
  ggplot2::facet_wrap(~.key) +
  ggplot2::theme(legend.position = "bottom")

# create topo plot
topoplot_eeg <- data_faces_ERPs %>%
  dplyr::group_by(condition) %>%
  dplyr::summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
  plot_topo() +
  ggplot2::facet_grid(~condition) +
  annotate_head() +
  ggplot2::geom_contour() +
  ggplot2::geom_text(colour = "black")

ica_plot <- data_faces_ERPs %>%
  dplyr::mutate(.recording = 1) %>%
  eeg_ica(-M1, -M2, -EOGV, -EOGH) %>%
  plot_components()

test_that("plotting doesn't change data", {
  # channel is factor in the plot and character in tibble, is that ok?
  expect_equal(as.matrix(lineplot_eeg$data), as.matrix(dplyr::as_tibble(smaller_data)))
  # lengths are very different
  expect_equal(
    nrow(topoplot_eeg$data),
    nrow(data_faces_ERPs %>%
      dplyr::group_by(condition) %>%
      dplyr::summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
      eeg_interpolate_tbl() %>%
      dplyr::filter(is.na(.key)))
  )
})


test_that("plot functions create ggplot2::ggplots", {
  expect_gg(plot)
  expect_gg(lineplot_eeg)
  expect_gg(topoplot_eeg)
  expect_gg(ica_plot)
  data_shorter <- dplyr::filter(data_faces_10_trials, between(as_time(.sample), 91, 93))
  expect_gg(plot(data_shorter) + annotate_events())
})

