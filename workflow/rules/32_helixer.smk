#!/usr/bin/env python3


def get_helixer_lineage(wildcards):
    helixer_lineage = genomes_dict[wildcards.genome]["helixer_lineage"]
    return Path("resources", "helixer_lineages", helixer_lineage)


# Note. Running this container on some HPCs doesn't work. I get "Error:
# helixer_post_bin not found in $PATH, this is required for Helixer.py to
# complete." See https://github.com/gglyptodon/helixer-docker/issues/11.
rule helixer:
    input:
        fasta=get_unmasked_fasta,
        lineage=get_helixer_lineage,
    output:
        gff=Path("results", "run", "{genome}", "helixer", "helixer.gff3"),
    log:
        Path("logs", "{genome}", "helixer", "helixer.log"),
    benchmark:
        Path("logs", "{genome}", "helixer", "helixer.stats.jsonl")
    container:
        tools_dict["helixer"]["container"]
    resources:
        gpu=1,
        runtime=lambda wildcards, attempt: int(attempt * 60),
        disk_mb=int(450e3),
    params:
        downloaded_model_path=subpath(input.lineage, parent=True),
        lineage=subpath(input.lineage, basename=True),
    shell:
        "mktemp && df -h ${{TMPDIR}} ; "
        "Helixer.py "
        "--lineage {params.lineage} "
        "--downloaded-model-path {params.downloaded_model_path} "
        "--fasta-path {input.fasta} "
        "--species {wildcards.genome} "
        "--gff-output-path {output.gff} "
        "&> {log} "
        "|| df -h ${{TMPDIR}}"


rule download_helixer_model:
    output:
        helixer_lineage=directory(
            Path("resources", "helixer_lineages", "{helixer_lineage}")
        ),
    log:
        "logs/download_helixer_model/{helixer_lineage}.log",
    retries: 3
    shadow:
        "minimal"
    container:
        tools_dict["helixer"]["container"]
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    params:
        outdir=subpath(output.helixer_lineage, parent=True),
    shell:
        "fetch_helixer_models.py "
        "--lineage {wildcards.helixer_lineage} "
        "--custom-path {params.outdir} "
        "&> {log}"
