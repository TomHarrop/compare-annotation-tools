#!/usr/bin/env Rscript

library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Pass results file")
} else {
  results_file <- args[1]
}

parsed_result_files <- list.files(
  "results",
  recursive = TRUE,
  full.names = TRUE,
  pattern = "parsed.csv"
)

names(parsed_result_files) <- sapply(
  parsed_result_files, function(x) {
    unlist(strsplit(x, split = "/", fixed = TRUE))[[6]]
  }
)

collated_stats <- rbindlist(
  lapply(
    parsed_result_files, fread
  ),
  idcol = "qc_file",
  fill = TRUE
)

fwrite(collated_stats, results_file)
