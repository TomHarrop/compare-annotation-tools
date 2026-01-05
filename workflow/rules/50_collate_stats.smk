# TODO: define the stats file types that will be collated across tools. Parse
# the stats for each tool and file type, then combine.


def get_qc_result(wildcards):
    raise ValueError(wildcards)


rule parse_json:
    input:
        get_qc_result,
    output:
        Path("results", "{genome}", "stats", "{tool}.{results_file}.{stat_file}.csv"),
    log:
        Path("logs", "{genome}", "parse_json", "{tool}.{results_file}.{stat_file}.log"),
    benchmark:
        Path(
            "logs", "{genome}", "parse_json", "{tool}.{results_file}.{stat_file}.stats"
        )
    threads: 1
    container:
        config["utils"]["r"]
    script:
        "scripts/parse_json.R"
