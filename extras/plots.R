#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)
library(lubridate)

#############
# FUNCTIONS #
#############

# metrics is a named vector mapping the metric to how we want it labelled on the
# plot, in the order we want them to appear.
MungNumericMetrics <- function(dt, metrics, qc_filename = NULL) {
  my_levels <- unique(rev(metrics))
  my_data <- dt[variable %in% names(metrics)]

  if (!is.null(qc_filename)) {
    my_data <- my_data[
      qc_file == qc_filename
    ]
  }

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

# TODO: define this somewhere else
order_order <- c(
  "Helotiales",
  "Asparagales",
  "Poales",
  "Hymenoptera",
  "Clupeiformes",
  "Atheriniformes",
  "Squamata",
  "Passeriformes"
)

order_palette <- viridisLite::magma(length(order_order))
names(order_palette) <- order_order

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
genome_orders <- sapply(config_yaml$genomes, function(x) x$ncbi_order)

dt[, genome_label := plyr::revalue(plyr::revalue(genome, labelled_genomes))]
dt[, genome_order := factor(
  plyr::revalue(genome, genome_orders),
  levels = order_order
)]
setorder(dt, genome_order)
dt[, genome_label := factor(genome_label, levels = unique(genome_label))]

# order the colour scale
order_label_cols <- order_palette[
  dt[
    ,
    as.character(genome_order)[[1]],
    by = genome_label
  ][, V1]
]


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

busco_pd <- MungNumericMetrics(
  dt = dt,
  metrics = busco_metrics,
  qc_filename = busco_filename
)

ggplot(busco_pd, aes(x = result_label, y = value, fill = variable_label)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
  ) +
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

omark_pd <- MungNumericMetrics(dt, omark_metrics, omark_filename)

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
  dt, omark_conserv_metrics, omark_filename
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

######################
# Annotation metrics #
######################

# Todo
#  - percentage of canonical splicing sites
#  - percentage with start and stop codons


# number of genes, mean CDS length, exons per transcript?
annot_metrics <- c(
  "Mikado.Stat.Exons per transcript.Median" = "Median Exons per transcript",
  # "Mikado.Stat.CDS lengths.Median" = "Median CDS length",
  "Mikado.Stat.Number of genes.Total" = "Total number of genes"
)


annot_pd <- MungNumericMetrics(dt, annot_metrics)


ggplot(annot_pd, aes(x = result_label, y = value, fill = result_label)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
    strip.placement = "outside"
  ) +
  scale_fill_viridis_d(guide = NULL) +
  scale_y_continuous(expand = 0.025) +
  xlab(NULL) +
  ylab(NULL) +
  facet_grid(variable_label ~ genome_label, scales = "free_y", switch = "y") +
  geom_col(position = "stack")
