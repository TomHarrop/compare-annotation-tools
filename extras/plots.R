#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)
library(lubridate)

# which stats files are available
stats_files <- list.files("results/collated_stats", full.names = TRUE)
mtimes <- sapply(x, file.mtime)
latest_stats <- names(
  sort(
    as_datetime(mtimes),
    decreasing = TRUE, na.last = TRUE
  )[1]
)

dt <- fread(latest_stats)

busco_metrics <- c(
  `Single copy` = "results.Single copy percentage",
  `Multi copy` = "results.Multi copy percentage",
  Fragmented = "results.Fragmented percentage",
  Missing = "results.Missing percentage"
)

busco_data <- dt[
  qc_file == "short_summary.specific.busco.json" & variable %in% busco_metrics
]

# mung
busco_data[, value := as.numeric(value)]
busco_data[, label := sub(" percentage", "", sub("results.", "", variable))]
busco_data[, label := factor(label, levels = names(busco_metrics))]


ggplot(busco_data, aes(x = tool, y = value, fill = label)) +
  facet_grid(~genome) +
  geom_col(position = "stack")
