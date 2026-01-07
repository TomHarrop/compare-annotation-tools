def check_format(possibly_gzipped_file):
    with gzip.open(possibly_gzipped_file, "r") as f:
        try:
            gzip_ok = f.read(1)
            return "fasta.gz"
        except gzip.BadGzipFile as e:
            return "fasta"


# local file if we have it, otherwise try remote
def get_fasta(wildcards):
    my_genome = genomes_dict[wildcards.genome]["fasta_file"]
    if exists(my_genome):
        return my_genome

    if my_genome.startswith("http://") or my_genome.startswith("https://"):
        return Path("resources", "{genome}", "input_genome")

    raise ValueError(f"Couldn't get FASTA file {my_genome}, check config.")


# n.b. whitespace in the header breaks braker
rule collect_fasta_file:
    input:
        get_fasta,
    output:
        Path("results", "run", "{genome}", "input_genome.fasta"),
    params:
        mem_pct=95,  # amount to assign to java
        format=lambda wildcards, input: check_format(input[0]),
    log:
        Path("logs", "{genome}", "collect_fasta_file.log"),
    benchmark:
        Path("logs", "{genome}", "collect_fasta_file.stats")
    retries: 0
    resources:
        mem=lambda wildcards, attempt: f"{int(2** attempt)}GB",
    container:
        utils["bbmap"]
    shell:
        "mem_mb=$(( {resources.mem_mb} * {params.mem_pct} / 100 )) ; "
        "cat {input}  "
        "| "
        "reformat.sh "
        "-Xmx${{mem_mb}}m "
        "fixheaders=t "
        "trimreaddescription=t "
        "ignorejunk=f "
        "in=stdin.{params.format} "
        "out={output} "
        "2> {log} "


# We need to download manually because the Snakemake http plugin breaks the
# bind path for Apptainer.
rule download_remote_fasta:
    output:
        temp(Path("resources", "{genome}", "input_genome")),
    params:
        url=lambda wildcards: genomes_dict[wildcards.genome]["fasta_file"],
    log:
        Path("logs", "download_remote_fasta", "{genome}.log"),
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 0
    container:
        utils["wget"]
    shell:
        "wget -O {output} {params.url} &> {log}"
