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


def get_busco_lineage(wildcards):
    return rules.expand_busco_lineage_files.output.busco_lineage.format(
        busco_lineage=genomes_dict[wildcards.genome]["busco_lineage"]
    )


# process the tool_dict to request the output
def get_results():

    all_target_files = []

    annotation_path = Path(
        "results", "{{genome}}", "{tool}", "annotation", "{results_file}"
    )
    qc_path = Path(
        "results",
        "{{genome}}",
        "{tool}",
        "qc",
        "{results_file}",
        "{qc_tool}",
        "{qc_file}",
    )

    for tool, tool_data in tools_dict.items():
        my_results_files = tool_data.get("result_files", [])

        annotation_output_files = expand(
            annotation_path, tool=tool, results_file=my_results_files
        )
        qc_output_files = []
        for qc_tool, qc_tool_data in qc_tools_dict.items():
            qc_files = expand(
                qc_path,
                tool=tool,
                results_file=my_results_files,
                qc_tool=qc_tool,
                qc_file=qc_tool_data.get("result_files", []),
            )
            for qc_file in qc_files:
                qc_output_files.append(qc_file)

        for file in annotation_output_files + qc_output_files:
            all_target_files.append(file)

    return all_target_files


def select_taxid(wildcards):
    return genomes_dict[wildcards.genome]["taxon_id"]
