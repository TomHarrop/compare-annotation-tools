#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)
library(lubridate)

# which stats files are available
stats_files <- list.files("results/collated_stats", full.names = TRUE)
mtimes <- sapply(stats_files, file.mtime)
latest_stats <- names(
  sort(
    as_datetime(mtimes),
    decreasing = TRUE, na.last = TRUE
  )[1]
)

dt <- fread(latest_stats)

# General settings
tool_order <- c(
  "braker.gff3" = "Braker3 (GFF)",
  "braker.gtf" = "Braker3 (GTF)",
  "funannotate.gff3" = "Funannotate",
  "tiberius.gtf" = "Tiberius"
)

dt[, result_label := factor(
  plyr::revalue(result_file, tool_order),
  levels = tool_order
)]

# Tool specific settings

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
busco_data[, label := factor(label, levels = rev(names(busco_metrics)))]


ggplot(busco_data, aes(x = result_label, y = value, fill = label)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(guide = guide_legend(title = NULL, reverse = TRUE)) +
  scale_y_continuous(expand = 0.025) +
  ylab(NULL) +
  xlab(NULL) +
  facet_grid(~genome) +
  geom_col(position = "stack")
