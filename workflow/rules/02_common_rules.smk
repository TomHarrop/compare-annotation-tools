# local file if we have it, otherwise try remote
def get_fasta(wildcards):
    my_genome = genomes_dict[wildcards.genome]["fasta_file"]
    if exists(my_genome):
        return my_genome

    if my_genome.startswith("http://") or my_genome.startswith("https://"):
        return storage.http(my_genome)

    raise ValueError(f"Couldn't get FASTA file {my_genome}, check config.")


# n.b. whitespace in the header breaks braker
rule collect_fasta_file:
    input:
        get_fasta,
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
