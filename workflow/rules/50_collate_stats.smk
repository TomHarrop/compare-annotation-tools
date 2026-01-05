# TODO: define the stats file types that will be collated across tools. Parse
# the stats for each tool and file type, then combine.


rule parse_json:
    input:
        get_qc_result,
    output:
        Path("results", "{genome}", "stats", "{tool}."),
