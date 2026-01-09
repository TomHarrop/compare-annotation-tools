#!/usr/bin/env Rscript

library(data.table)

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
# SLURM GPUs per node. (i.e. we are charged 64 SU/hour of GPU, as long as we
# request 1 GPU). High mem nodes have 987.5 GB RAM and are also charged at 128
# SU/hour.

# See https://pawseysc.github.io/su-calculator/ and
# https://pawsey.atlassian.net/wiki/spaces/US/pages/51929028/Setonix+General+Information.

cpus_per_node <- 128
ram_per_node <- 230
gpu_scaling_factor <- 64

# I believe SLURM uses PSS (although it reports it as RSS). That's why it's used
# in this script.

tool_order <- c(
  "braker3.stats" = "Braker3",
  "funannotate.stats" = "Funannotate",
  "tiberius.stats" = "Tiberius",
  "helixer.stats" = "Helixer"
)


if (exists("snakemake")) {} else {
  last <- function(x) {
    return(x[length(x)])
  }


  all_stat_files <- list.files(
    "logs",
    pattern = ".stats$", recursive = TRUE, full.names = TRUE
  )
  names(all_stat_files) <- all_stat_files
  keep <- sapply(
    all_stat_files, function(x) {
      last(unlist(strsplit(x, "/", fixed = TRUE))) %in% names(tool_order)
    }
  )
  annotation_stat_files <- all_stat_files[keep]
}

dt <- rbindlist(lapply(annotation_stat_files, fread), idcol = "stat_file")


dt[, `Service units consumed` := threads * s]
