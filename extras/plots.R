#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)
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

###########
# GLOBALS #
###########


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


# get the labels from the config file
config_file <- "config/benchmark.yaml"
config_yaml <- yaml::read_yaml(config_file)
labelled_genomes <- sapply(config_yaml$genomes, function(x) x$label)

dt[, genome_label := plyr::revalue(plyr::revalue(genome, labelled_genomes))]


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
  facet_grid(~genome_label) +
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

# we have to subtract the partial and fragmented results to get the plot to look
# right
hit_type_order <- c("Partial", "Fragmented", "Total", "Remainder")


omark_pd[endsWith(variable, "_fragmented"), hit_type := "Fragmented"]
omark_pd[endsWith(variable, "_partial_hits"), hit_type := "Partial"]
omark_pd[is.na(hit_type), hit_type := "Total"]
omark_pd_wide <- dcast(
  omark_pd, genome_label + result_label + variable_label ~ hit_type,
  value.var = "value"
)
omark_pd_wide[
  ,
  Remainder := Total - (ifelse(
    is.na(Fragmented), 0, Fragmented
  ) + ifelse(
    is.na(Partial), 0, Partial
  ))
]

omark_modified_pd <- melt(omark_pd_wide,
  id.vars = c("genome_label", "result_label", "variable_label"),
  variable.name = "hit_type",
  variable.factor = FALSE
)
omark_modified_pd[, hit_type := factor(hit_type, levels = hit_type_order)]

setorder(omark_modified_pd, -"variable_label", "hit_type")
omark_modified_pd[
  ,
  group_variable := paste(variable_label, hit_type, sep = ".")
]
omark_modified_pd[
  ,
  group_variable := factor(group_variable, levels = rev(unique(group_variable)))
]

ggplot(
  omark_modified_pd[hit_type != "Total"],
  aes(
    x = result_label,
    y = value,
    fill = variable_label,
    linetype = hit_type,
    group = group_variable
  ),
) +
  facet_grid(~genome_label) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(
    guide = guide_legend(
      title = NULL,
      reverse = TRUE,
      override.aes = list(colour = NA)
    ),
    alpha = 0.8
  ) +
  scale_linetype_manual(
    values = c(2, 3, 0),
    breaks = c(
      "Partial", "Fragmented"
    ),
    guide = guide_legend(
      title = NULL,
      override.aes = list(fill = NA),
    )
  ) +
  scale_y_continuous(expand = 0) +
  xlab(NULL) +
  ylab("%") +
  geom_col(position = "stack", linewidth = 0.5, colour = "black")


# omark conserv is the same as BUSCO, i think?
omark_conserv_pd <- MungNumericMetrics(
  dt, omark_filename, omark_conserv_metrics
)


ggplot(omark_conserv_pd, aes(x = result_label, y = value, fill = variable_label)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_fill_viridis_d(guide = guide_legend(title = NULL, reverse = TRUE)) +
  scale_y_continuous(expand = 0.025) +
  xlab(NULL) +
  ylab("%") +
  facet_grid(~genome) +
  geom_col(position = "stack")
