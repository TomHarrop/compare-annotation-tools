#!/usr/bin/env python3


def annotation_results(genome, tool):
    annotation_result_files = expand(
        annotation_path,
        genome=genome,
        tool=tool,
        result_file=get_tool_result_files(tool),
    )

    return annotation_result_files


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
    shell(
        "apptainer exec "
        + config["utils"]["r"]
        + " "
        + "Rscript workflow/scripts/collate_stats.R "
        + stats_file
    )
    return stats_file


def get_all_results():
    results = []
    for tool in all_tools:
        for file in get_all_tool_results(tool):
            results.append(file)
    return results


def get_all_genome_results(genome):
    results = []
    for tool in all_tools:
        for file in annotation_results(genome, tool):
            results.append(file)
        for file in qc_results(genome, tool):
            results.append(file)
        for file in stats_results(genome, tool):
            results.append(file)
    return results


def get_all_tool_results(tool):
    results = []
    for genome in all_genomes:
        for file in annotation_results(genome, tool):
            results.append(file)
        for file in qc_results(genome, tool):
            results.append(file)
        for file in stats_results(genome, tool):
            results.append(file)
    return results


def get_busco_lineage(wildcards):
    genome = wildcards.get("genome")
    tool = wildcards.get("tool")
    try:
        busco_lineage = genomes_dict[genome]["overrides"][tool]["busco_lineage"]
    except KeyError as e:
        busco_lineage = genomes_dict[genome]["busco_lineage"]

    return rules.expand_busco_lineage_files.output.busco_lineage.format(
        busco_lineage=busco_lineage
    )


# process the tool_dict to request the output
def get_tool_result_files(tool):
    tool_data = tools_dict.get(tool)
    return tool_data.get("result_files")


def get_qc_result_files(qc_tool):
    qc_tool_data = qc_tools_dict.get(qc_tool)
    return qc_tool_data.get("result_files")


def qc_results(genome, tool):
    qc_output_files = []
    for qc_tool in qc_tools_dict.keys():
        qc_files = expand(
            qc_path,
            genome=genome,
            tool=tool,
            result_file=get_tool_result_files(tool),
            qc_tool=qc_tool,
            qc_file=get_qc_result_files(qc_tool),
        )
        for qc_file in qc_files:
            qc_output_files.append(qc_file)
    return qc_output_files


def select_taxid(wildcards):
    return genomes_dict[wildcards.genome]["taxon_id"]


def stats_results(genome, tool):
    stats_output_files = []
    for qc_tool in qc_tools_dict.keys():
        parsable_stats_files = [
            x
            for x in get_qc_result_files(qc_tool)
            if x.endswith(".json") or x.endswith("AnnoOddities.oddity_summary.txt")
        ]
        stats_files = expand(
            stats_path,
            genome=genome,
            tool=tool,
            result_file=get_tool_result_files(tool),
            qc_file=parsable_stats_files,
        )
        for stats_file in stats_files:
            stats_output_files.append(stats_file)
    return stats_output_files
