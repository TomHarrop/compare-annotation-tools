#!/usr/bin/env python3


def get_helixer_lineage(wildcards):
    helixer_lineage = genomes_dict[wildcards.genome]["helixer_lineage"]
    return Path("resources", "helixer_lineages", helixer_lineage)


rule helixer:
    input:
        unpack(annotation_tool_input_dict),
        lineage=get_helixer_lineage,
    output:
        gff=Path("results", "run", "{genome}", "helixer", "helixer.gff3"),
    params:
        downloaded_model_path=subpath(input.lineage, parent=True),
        lineage=subpath(input.lineage, basename=True),
    log:
        Path("logs", "{genome}", "helixer", "helixer.log"),
    benchmark:
        Path("logs", "{genome}", "helixer", "helixer.stats")
    container:
        tools_dict["helixer"]["container"]
    shell:
        "Helixer.py "
        "--lineage {params.lineage} "
        "--downloaded-model-path {params.downloaded_model_path} "
        "--fasta-path {input.fasta} "
        "--species {wildcards.genome} "
        "--gff-output-path {output.gff} "
        "&> {log}"


rule download_helixer_model:
    output:
        helixer_lineage=directory(
            Path("resources", "helixer_lineages", "{helixer_lineage}")
        ),
    log:
        "logs/download_helixer_model/{helixer_lineage}.log",
    params:
        outdir=subpath(output.helixer_lineage, parent=True),
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 3
    shadow:
        "minimal"
    container:
        tools_dict["helixer"]["container"]
    shell:
        "fetch_helixer_models.py "
        "--lineage {wildcards.helixer_lineage} "
        "--custom-path {params.outdir} "
        "&> {log}"
