#!/usr/bin/env Rscript

library(data.table)
library(jsonlite)

ParseJsonToDt <- function(json_file, genome, tool_name) {
  nested_list <- fromJSON(json_file, flatten = TRUE)
  wide_dt <- as.data.table(t(unlist(nested_list)))
  wide_dt[, genome := genome]
  wide_dt[, tool := tool_name]
  return(melt(wide_dt, id.vars = c("genome", "tool")))
}


if (exists("snakemake")) {
  log <- file(snakemake@log[[1]], open = "wt")
  sink(log, type = "message")
  sink(log, append = TRUE, type = "output")
} else {
  # ao_stats_files <- list.files(
  #   "results",
  #   pattern = "AnnoOddities.combined_statistics.json",
  #   recursive = TRUE,
  #   full.names = TRUE
  # )
  # ao_oddity_files <- list.files(
  #   "results",
  #   pattern = "AnnoOddities.oddity_summary.txt",
  #   recursive = TRUE,
  #   full.names = TRUE
  # )
  # omark_summary_files <- list.files(
  #   "results",
  #   pattern = "omark_summary.json",
  #   recursive = TRUE,
  #   full.names = TRUE
  # )
  # busco_summary_files <- list.files(
  #   "results",
  #   pattern = "short_summary.specific.busco.json",
  #   recursive = TRUE,
  #   full.names = TRUE
  # )

  json_file <- "results/test_genome_with_rnaseq/funannotate/qc/funannotate.gff3/annooddities/AnnoOddities.combined_statistics.json"
  genome <- "test_genome_with_rnaseq"
  tool_name <- "FIXME"
}

long_dt <- ParseJsonToDt(json_file, genome, tool_name)

ParseJsonToDt("results/test_genome_with_rnaseq/funannotate/qc/funannotate.gff3/atol_qc_annotation/short_summary.specific.busco.json", "genome", "fa")
