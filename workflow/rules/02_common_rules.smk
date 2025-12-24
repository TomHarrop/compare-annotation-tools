# n.b. whitespace in the header breaks braker
rule collect_fasta_file:
    input:
        lambda wildcards: genomes_dict[wildcards.genome]["fasta_file"],
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
