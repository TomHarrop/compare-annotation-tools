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


def get_tool_result_files(wildcards):
    tool_result_filenames = tools_dict[wildcards.tool]["result_files"]
    tool_result_path = Path("results", "run", wildcards.genome, wildcards.tool)
    tool_result_files = [Path(tool_result_path, x) for x in tool_result_filenames]
    return tool_result_files


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
