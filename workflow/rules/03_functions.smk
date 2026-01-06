#!/usr/bin/env python3


def annotation_tool_input_dict(wildcards):
    my_genome_dict = genomes_dict[wildcards.genome]
    input_dict = {"fasta": Path("results", "run", "{genome}", "input_genome.fasta")}

    try:
        logger.info(f"Using RNAseq {my_genome_dict["rnaseq"]}")
        input_dict["rnaseq"] = Path("results", "run", "{genome}", "rnaseq.bam")
        input_dict["rnaseq_counted"] = Path(
            "results", "run", wildcards.genome, "rnaseq_reads_ok"
        )
    except KeyError:
        logger.info(f"No rnaseq for {wildcards.genome}")

    return input_dict


def collate_stats():
    collated_stats_dir = Path("results", "collated_stats")
    collated_stats_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        dir=collated_stats_dir,
        suffix=".csv",
        prefix=f"collated_stats.{date.today().isoformat()}.",
    ) as fp:
        stats_file = fp.name
    shell("Rscript workflow/scripts/collate_stats.R " + stats_file)


def get_busco_lineage(wildcards):
    return rules.expand_busco_lineage_files.output.busco_lineage.format(
        busco_lineage=genomes_dict[wildcards.genome]["busco_lineage"]
    )


# process the tool_dict to request the output
def get_results():

    all_target_files = []

    annotation_path = Path(
        "results", "{{genome}}", "{tool}", "annotation", "{result_file}"
    )
    qc_path = Path(
        "results",
        "{{genome}}",
        "{tool}",
        "qc",
        "{result_file}",
        "{qc_tool}",
        "{qc_file}",
    )
    stats_path = Path(
        "results",
        "{{genome}}",
        "{tool}",
        "stats",
        "{result_file}",
        "{qc_file}",
        "parsed.csv",
    )

    for tool, tool_data in tools_dict.items():
        my_result_files = tool_data.get("result_files", [])

        annotation_output_files = expand(
            annotation_path, tool=tool, result_file=my_result_files
        )
        qc_output_files = []
        stats_files = []
        for qc_tool, qc_tool_data in qc_tools_dict.items():
            qc_tool_data_result_files = qc_tool_data.get("result_files", [])
            qc_files = expand(
                qc_path,
                tool=tool,
                result_file=my_result_files,
                qc_tool=qc_tool,
                qc_file=qc_tool_data_result_files,
            )
            for qc_file in qc_files:
                qc_output_files.append(qc_file)

            my_stats_files = expand(
                stats_path,
                tool=tool,
                result_file=my_result_files,
                qc_tool=qc_tool,
                qc_file=[x for x in qc_tool_data_result_files if x.endswith(".json")],
            )
            for stats_file in my_stats_files:
                stats_files.append(stats_file)

        for file in annotation_output_files + qc_output_files + stats_files:
            all_target_files.append(file)

    return all_target_files


def select_taxid(wildcards):
    return genomes_dict[wildcards.genome]["taxon_id"]
