#!/usr/bin/env Rscript

library(data.table)
library(ggplot2)

###########
# GLOBALS #
###########

# Roughly, 1 CPU for an hour is 1 SU. Pawsey charges us 64 (although some docs
# say 32) service units for an hour of GPU.
# The formula is:

# Partition Charge Rate ✕ Max(Cores Proportion, Memory Proportion, GPU
#   Proportion) ✕ N. of nodes requested ✕ Job Elapsed Time (Hours).

# The partition charge rates are 128 SU / hour for standard and 512 SU / hour
# for GPU.

# Based on the calculator, nodes have 128 cores and 230 GB RAM. GPUs have 8
# SLURM GPUs per node. 1 core and 2 GB of RAM are roughly the same cost. (also,
# we are charged 64 SU/hour of GPU, as long as we request 1 GPU). High mem nodes
# have 987.5 GB RAM and are also charged at 128 SU/hour.

# See https://pawseysc.github.io/su-calculator/ and
# https://pawsey.atlassian.net/wiki/spaces/US/pages/51929028/Setonix+General+Information.

cpus_per_node <- 128
ram_per_node <- 230
gpus_per_node <- 8

node_charge_per_hour <- 128
gpu_node_charge_per_hour <- 512

# I believe SLURM uses PSS (although it reports it as RSS). That's why it's used
# in this script.

tool_order <- c(
  "braker3.stats.jsonl" = "Braker3",
  "funannotate.stats.jsonl" = "Funannotate",
  "tiberius.stats.jsonl" = "Tiberius",
  "helixer.stats.jsonl" = "Helixer"
)


if (exists("snakemake")) {} else {
  last <- function(x) {
    return(x[length(x)])
  }


  all_stat_files <- list.files(
    "logs",
    pattern = ".stats.jsonl$", recursive = TRUE, full.names = TRUE
  )
  names(all_stat_files) <- all_stat_files
  keep <- sapply(
    all_stat_files, function(x) {
      basename(x) %in% names(tool_order)
    }
  )
  # annotation_stat_files <- all_stat_files #FIXME
  annotation_stat_files <- all_stat_files[keep]
}

# read teh JSON files
dt <- rbindlist(
  lapply(annotation_stat_files, function(x) {
    as.data.table(
      jsonlite::stream_in(
        file(x),
        flatten = TRUE
      )
    )
  }),
  idcol = "stat_file",
  fill = TRUE
)


# get the labels from the config file
config_file <- "config/test.yaml"
config_yaml <- yaml::read_yaml(config_file)
labelled_genomes <- sapply(config_yaml$genomes, function(x) x$label)

dt[
  , genome_label := plyr::revalue(
    plyr::revalue(wildcards.genome, labelled_genomes)
  )
]

# Parse the tool names etc.
dt[
  , tool_label := factor(
    plyr::revalue(basename(stat_file), tool_order),
    levels = tool_order
  )
]

# Calculate the costs
dt[
  resources.gpu > 0,
  job_su_per_hour := (resources.gpu / gpus_per_node) * gpu_node_charge_per_hour
]
dt[
  is.na(resources.gpu),
  job_su_per_hour := node_charge_per_hour * max(c(threads / cpus_per_node, max_pss / (ram_per_node * 1024))),
  by = stat_file
]
dt[, `Service units (approx.)` := job_su_per_hour * (s / (60 * 60))]
dt[, `Wall time (h)` := s / (60 * 60)]

# calculate resource usage
dt[, "Peak RAM (GB)" := max_pss / (1024 * 1024)]

# melt
pd <- melt(
  dt,
  id.vars = c("wildcards.genome", "tool_label"),
  measure.vars = c("Service units (approx.)", "Wall time (h)", "Peak RAM (GB)", "cpu_usage")
)


ggplot(pd, aes(x = tool_label, fill = wildcards.genome, y = value)) +
  facet_grid(variable ~ ., scales = "free_y", switch = "y") +
  theme_minimal() +
  theme(strip.placement = "outside") +
  scale_fill_viridis_d(guide = guide_legend(title = NULL, position = "top")) +
  ylab(NULL) +
  xlab(NULL) +
  geom_col(position = "dodge")
