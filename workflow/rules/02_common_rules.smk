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
        return Path("resources", "http", "{genome}", "input_genome")

    if my_genome.startswith("s3://"):

        return Path("resources", "s3", "{genome}", "input_genome")

    raise ValueError(f"Couldn't get FASTA file {my_genome}, check config.")


# n.b. whitespace in the header breaks braker
rule collect_fasta_file:
    input:
        get_fasta,
    output:
        Path("results", "run", "{genome}", "input_genome.fasta"),
    log:
        Path("logs", "{genome}", "collect_fasta_file.log"),
    benchmark:
        Path("logs", "{genome}", "collect_fasta_file.stats.jsonl")
    retries: 2
    container:
        utils["bbmap"]
    resources:
        mem=lambda wildcards, attempt: f"{int(2**(attempt+1))}GB",
    params:
        mem_pct=95,  # amount to assign to java
        format=lambda wildcards, input: check_format(input[0]),
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
        temp(Path("resources", "http", "{genome}", "input_genome")),
    log:
        Path("logs", "download_remote_fasta", "{genome}.log"),
    retries: 2
    container:
        utils["wget"]
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    params:
        url=lambda wildcards: genomes_dict[wildcards.genome]["fasta_file"],
    shell:
        "wget -O {output} {params.url} &> {log}"


# FIXME This is not working on the Spartan worker nodes but it does work on the
# head node (without SLURM)


def check_env_var(var, default=None):
    value = os.getenv(var)
    if value is None and default:
        return default
    if value is None:
        raise WorkflowError(f"Environment variable {var} not set")
    return value


rule download_s3_fasta:
    output:
        s3_fasta=temp(Path("resources", "s3", "{genome}", "input_genome")),
    log:
        Path("logs", "download_s3_fasta", "{genome}.log"),
    retries: 2
    container:
        utils["rclone"]
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 180),
        shell_exec="sh",
    params:
        s3_access_key_id=check_env_var("RCLONE_S3_ACCESS_KEY_ID"),
        s3_endpoint=check_env_var("RCLONE_S3_ENDPOINT"),
        s3_provider=check_env_var("RCLONE_S3_PROVIDER", "Ceph"),
        s3_secret_access_key=check_env_var("RCLONE_S3_SECRET_ACCESS_KEY"),
        url=lambda wildcards: genomes_dict[wildcards.genome]["fasta_file"],
        outdir=subpath(output.s3_fasta, parent=True),
        filename=lambda wildcards: Path(
            genomes_dict[wildcards.genome]["fasta_file"]
        ).name,
    shell:
        "rclone "
        "--s3-access-key-id {params.s3_access_key_id} "
        "--s3-endpoint {params.s3_endpoint} "
        "--s3-provider {params.s3_provider} "
        "--s3-secret-access-key {params.s3_secret_access_key} "
        "copy "
        ":{params.url} "
        "{params.outdir} "
        "&> {log} "
        "&& "
        "mv {params.outdir}/{params.filename} {output}"
