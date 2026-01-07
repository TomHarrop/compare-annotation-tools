#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)
library(ggpattern)
library(lubridate)

#############
# FUNCTIONS #
#############

# metrics is a named vector mapping the metric to how we want it labelled on the
# plot, in the order we want them to appear.
MungNumericMetrics <- function(dt, qc_filename, metrics) {
  my_levels <- unique(rev(metrics))
  my_data <- dt[
    qc_file == qc_filename & variable %in% names(metrics)
  ]
  my_data[, value := as.numeric(value)]
  my_data[, variable_label := factor(
    plyr::revalue(variable, metrics),
    levels = my_levels
  )]
  return(my_data)
}

########
# MAIN #
########

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
  "tiberius.gtf" = "Tiberius",
  "helixer.gff3" = "Helixer"
)

dt[, result_label := factor(
  plyr::revalue(result_file, tool_order),
  levels = tool_order
)]


#########
# BUSCO #
#########

busco_filename <- "short_summary.specific.busco.json"
busco_metrics <- c(
  "results.Single copy percentage" = "Single copy",
  "results.Multi copy percentage" = "Multi copy",
  "results.Fragmented percentage" = "Fragmented",
  "results.Missing percentage" = "Missing"
)

busco_pd <- MungNumericMetrics(dt, busco_filename, busco_metrics)

ggplot(busco_pd, aes(x = result_label, y = value, fill = variable_label)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(guide = guide_legend(title = NULL, reverse = TRUE)) +
  scale_y_continuous(expand = 0.025) +
  xlab(NULL) +
  ylab("%") +
  facet_grid(~genome) +
  geom_col(position = "stack")

#########
# OMArk #
#########

omark_filename <- "omark_summary.json"

omark_conserv_metrics <- c(
  "conserv_pcts.single" = "Single",
  "conserv_pcts.duplicated_unexpected" = "Duplicated (unexpected)",
  "conserv_pcts.duplicated_expected" = "Duplicated (expected)",
  "conserv_pcts.missing" = "Missing"
)

omark_metrics <- c(
  "results_pcts.consistent" = "Consistent",
  "results_pcts.consistent_partial_hits" = "Consistent",
  "results_pcts.consistent_fragmented" = "Consistent",
  "results_pcts.inconsistent" = "Inconsistent",
  "results_pcts.inconsistent_partial_hits" = "Inconsistent",
  "results_pcts.inconsistent_fragmented" = "Inconsistent",
  "results_pcts.likely_contamination" = "Contamination",
  "results_pcts.likely_contamination_partial_hits" = "Contamination",
  "results_pcts.likely_contamination_fragmented" = "Contamination",
  "results_pcts.unknown" = "Unknown"
)

omark_pd <- MungNumericMetrics(dt, omark_filename, omark_metrics)

omark_pd[endsWith(variable, "_fragmented"), hit_type := "Fragmented"]
omark_pd[endsWith(variable, "_partial_hits"), hit_type := "Partial"]

x <- ggplot(omark_pd[is.na(hit_type)], aes(x = result_label, y = value, fill = variable_label)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(guide = guide_legend(title = "Category", reverse = TRUE)) +
  scale_y_continuous(expand = 0.025) +
  xlab(NULL) +
  ylab("%") +
  facet_grid(~genome) +
  geom_col(position = "stack")

# FIXME. I don't think this shows the different hit type for each category
x + geom_col_pattern(
  mapping = aes(pattern_angle = hit_type),
  data = omark_pd[!is.na(hit_type)],
  position = "stack",
  colour = NA,
  fill = NA,
  pattern = "stripe",
  pattern_fill = "black",
  pattern_colour = NA,
  # pattern_angle = 45,
  pattern_density = 0.2,
  pattern_spacing = 0.025,
  pattern_size = 0.2,
  pattern_scale = 0.1,
  pattern_key_scale_factor = 0.5
) +
  # scale_pattern_manual(
  #   values = c("stripe", "crosshatch"),
  #   guide = guide_legend(title = "Hit Type")
  # )
  scale_pattern_angle_manual(values = c(30, 120))

omark_conerv_pd <- MungNumericMetrics(
  dt, omark_filename, omark_conserv_metrics
)


ggplot(omark_conerv_pd, aes(x = result_label, y = value, fill = variable_label)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(guide = guide_legend(title = NULL, reverse = TRUE)) +
  scale_y_continuous(expand = 0.025) +
  xlab(NULL) +
  ylab("%") +
  facet_grid(~genome) +
  geom_col(position = "stack")
