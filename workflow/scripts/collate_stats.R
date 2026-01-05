#!/usr/bin/env Rscript

library(data.table)
library(jsonlite)

ParseJsonToDt <- function(x) {
  nested_list <- fromJSON(ao_stats_files[[1]], flatten = TRUE)
  return(as.data.table(t(unlist(nested_list))))
}


if (exists("snakemake")) {
  log <- file(snakemake@log[[1]], open = "wt")
  sink(log, type = "message")
  sink(log, append = TRUE, type = "output")
} else {
  ao_stats_files <- list.files(
    "results",
    pattern = "AnnoOddities.combined_statistics.json",
    recursive = TRUE,
    full.names = TRUE
  )
  ao_oddity_files <- list.files(
    "results",
    pattern = "AnnoOddities.oddity_summary.txt",
    recursive = TRUE,
    full.names = TRUE
  )
  omark_summary_files <- list.files(
    "results",
    pattern = "omark_summary.json",
    recursive = TRUE,
    full.names = TRUE
  )
  busco_summary_files <- list.files(
    "results",
    pattern = "short_summary.specific.busco.json",
    recursive = TRUE,
    full.names = TRUE
  )
}

blah <- lapply(ao_stats_files, ParseJsonToDt)
rbindlist(blah, )
