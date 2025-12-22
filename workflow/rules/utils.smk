def annotation_tool_input_dict(wildcards):
    my_genome_dict = genomes_dict[wildcards.genome]
    input_dict = {"fasta": Path("results", "run", "{genome}", "input_genome.fasta")}

    try:
        input_dict["rnaseq"] = my_genome_dict["rnaseq"]
        input_dict["rnaseq_counted"] = Path(
            "results", "run", wildcards.genome, "rnaseq_reads_ok"
        )
    except KeyError:
        logger.info(f"No rnaseq for {wildcards.genome}")

    return input_dict


def get_fasta_path(wildcards):
    return genomes_dict[wildcards.genome]["fasta_file"]


def get_rnaseq_path(wildcards):
    return genomes_dict[wildcards.genome]["rnaseq"]


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


genomes_dict = config["genomes"]
tools_dict = config["tools"]
utils = config["utils"]
qc_tools_dict = config["qc"]
tiberius_models = tools_dict["tiberius"]["models"].keys()

all_genomes = sorted(set(genomes_dict.keys()))
all_tools = sorted(set(tools_dict.keys()))
all_result_files = list(
    rf for td in tools_dict.values() for rf in td.get("result_files", [])
)
qc_result_files = list(
    rf for td in qc_tools_dict.values() for rf in td.get("result_files", [])
)


wildcard_constraints:
    genome="|".join(all_genomes),
    qc_file="|".join(qc_result_files),
    result_file="|".join(all_result_files),
    tiberius_model="|".join(tiberius_models),
    tool="|".join(all_tools),


# n.b. whitespace in the header breaks braker
rule collect_fasta_file:
    input:
        get_fasta_path,
    output:
        Path("results", "run", "{genome}", "input_genome.fasta"),
    params:
        mem_pct=95,  # amount to assign to java
    log:
        Path("logs", "{genome}", "collect_fasta_file.log"),
    benchmark:
        Path("logs", "{genome}", "collect_fasta_file.stats")
    retries: 5
    resources:
        mem=lambda wildcards, attempt: f"{int(2** attempt)}GB",
    container:
        utils["bbmap"]
    shell:
        "mem_mb=$(( {resources.mem_mb} * {params.mem_pct} / 100 )) ; "
        "reformat.sh "
        "-Xmx${{mem_mb}}m "
        "fixheaders=t "
        "trimreaddescription=t "
        "ignorejunk=f "
        "in={input} "
        "out={output} "
        "2>{log} "
