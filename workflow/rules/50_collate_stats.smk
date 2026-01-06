# TODO: define the stats file types that will be collated across tools. Parse
# the stats for each tool and file type, then combine.


@cache
def collate_qc_output_files(wildcards):
    qc_output = sorted(
        set(Path(x.apply_wildcards(wildcards)) for x in rules.atol_qc_annotation.output)
    )
    ao_output = sorted(
        set(Path(x.apply_wildcards(wildcards)) for x in rules.annooddities.output)
    )
    all_output = sorted(set(qc_output + ao_output))
    return {x.name: x for x in all_output}


def get_qc_result(wildcards):
    my_qc_output = collate_qc_output_files(wildcards)
    raise ValueError("why am I here # FIXME")
    return my_qc_output[wildcards.qc_file]


# parsed_stats = expand(
#     Path(
#         "results",
#         "{{genome}}",
#         "{{tool}}",
#         "stats",
#         "{result_file}",
#         "{qc_file}",
#         "parsed.csv",
#     ),
#     zip,
#     result_file=all_result_files,
#     qc_file=qc_result_files,
# )

# raise ValueError(parsed_stats)

# rule combine_stats_csvs:
#     input:
#         parsed_stats,


rule parse_tsv:
    input:
        Path(
            "results",
            "{genome}",
            "{tool}",
            "qc",
            "{result_file}",
            "annooddities",
            "AnnoOddities.oddity_summary.txt",
        ),
    output:
        temp(
            Path(
                "results",
                "{genome}",
                "{tool}",
                "stats",
                "{result_file}",
                "AnnoOddities.oddity_summary.txt",
                "parsed.csv",
            )
        ),
    log:
        Path(
            "logs",
            "{genome}",
            "parse_json",
            "{tool}.{result_file}.AnnoOddities.oddity_summary.txt.log",
        ),
    benchmark:
        Path(
            "logs",
            "{genome}",
            "parse_json",
            "{tool}.{result_file}.AnnoOddities.oddity_summary.txt.stats",
        )
    threads: 1
    container:
        config["utils"]["r"]
    shell:
        "Rscript -e "
        "'library(data.table); "
        'x <- fread("{input}") ; '
        'setnames(x, c("variable", "value")) ; '
        'x[, genome := "{wildcards.genome}"] ; '
        'x[, tool := "{wildcards.tool}"] ; '
        'x[, result_file := "{wildcards.result_file}"] ; '
        'fwrite(x, "{output}") ; '
        "sessionInfo()' "
        "&> {log}"


rule parse_json:
    input:
        json=get_qc_result,
    output:
        csv=temp(
            Path(
                "results",
                "{genome}",
                "{tool}",
                "stats",
                "{result_file}",
                "{qc_file}",
                "parsed.csv",
            )
        ),
    log:
        Path("logs", "{genome}", "parse_json", "{tool}.{result_file}.{qc_file}.log"),
    benchmark:
        Path("logs", "{genome}", "parse_json", "{tool}.{result_file}.{qc_file}.stats")
    threads: 1
    container:
        config["utils"]["r"]
    script:
        "../scripts/parse_json.R"
