#!/usr/bin/env python3


def get_tiberius_model(wildcards):
    tiberius_model = genomes_dict[wildcards.genome]["tiberius_model"]
    return Path("resources", "tiberius_models", tiberius_model)


rule tiberius:
    input:
        unpack(annotation_tool_input_dict),
        model=get_tiberius_model,
    output:
        gtf=Path("results", "run", "{genome}", "tiberius", "tiberius.gtf"),
    params:
        batch_size=16,
    log:
        Path("logs", "{genome}", "tiberius", "tiberius.log"),
    benchmark:
        Path("logs", "{genome}", "tiberius", "tiberius.stats")
    resources:
        gpu=1,
        mem=lambda wildcards, attempt: f"{int(attempt*16)}G",  # scales with the longest contig
        runtime=lambda wildcards, attempt: int(attempt * 60),
    container:
        tools_dict["tiberius"]["container"]
    shell:
        "tiberius.py "
        "--genome {input.fasta} "
        "--model {input.model} "
        "--out {output.gtf} "
        "--batch_size {params.batch_size} "
        "&> {log}"


rule expand_tiberius_model:
    input:
        "resources/tiberius_model_files/{tiberius_model}.tar.gz",
    output:
        directory("resources/tiberius_models/{tiberius_model}"),
    log:
        "logs/expand_tiberius_model/{tiberius_model}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    shadow:
        "minimal"
    container:
        utils["debian"]
    shell:
        "mkdir -p {output} && "
        "tar -zxf {input} -C {output} --strip-components 1 &> {log} && "
        "printf $(date -Iseconds) > {output}/TIMESTAMP"


rule download_tiberius_model:
    output:
        temp("resources/tiberius_model_files/{tiberius_model}.tar.gz"),
    params:
        model_url=lambda wildcards: tools_dict["tiberius"]["models"][
            wildcards.tiberius_model
        ],
    log:
        "logs/download_tiberius_model/{tiberius_model}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 3
    shadow:
        "minimal"
    container:
        utils["wget"]
    shell:
        "wget -O {output} {params.model_url} &> {log}"
