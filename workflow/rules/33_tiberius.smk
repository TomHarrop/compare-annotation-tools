#!/usr/bin/env python3


def check_if_tiberius_model_requires_softmasking(tiberius_model_name):
    return tiberius_model_name in tools_dict["tiberius"]["requires_softmasking"]


def get_tiberius_fasta(wildcards):
    tiberius_model_name = get_tiberius_model_name(wildcards)
    requires_softmasking = check_if_tiberius_model_requires_softmasking(tiberius_model_name)
    if requires_softmasking:
        return get_softmasked_fasta(wildcards)
    return get_unmasked_fasta(wildcards)


def get_tiberius_model_name(wildcards):
    return genomes_dict[wildcards.genome]["tiberius_model"]


def get_tiberius_model_cfg(wildcards):
    tiberius_model_name = get_tiberius_model_name(wildcards)
    return tools_dict["tiberius"]["models"][tiberius_model_name]


# The softmasking param is confusing. Models that *require* softmasking need to
# be designated in the config. These models should only be run against masked
# genomes.
#
# If you try to run a non-softmasked model, you get the following message (even
# with a soft-masked genome).
#
# This appears to be a softmasking compatibility issue. The model was trained
# without softmasking, but inference is running with softmasking enabled.
# SOLUTION: Add the '--no_softmasking' flag to your command, or use a model
# trained with softmasking.
def get_tiberius_softmask_param(wildcards, input):
    tiberius_model_name = get_tiberius_model_name(wildcards)
    requires_softmasking = check_if_tiberius_model_requires_softmasking(
        tiberius_model_name
    )
    return "" if requires_softmasking else "--no_softmasking"


rule tiberius:
    input:
        fasta=get_tiberius_fasta,
    output:
        gtf=Path("results", "run", "{genome}", "tiberius", "tiberius.gtf"),
    log:
        Path("logs", "{genome}", "tiberius", "tiberius.log"),
    benchmark:
        Path("logs", "{genome}", "tiberius", "tiberius.stats.jsonl")
    container:
        tools_dict["tiberius"]["container"]
    resources:
        gpu=1,
        mem=lambda wildcards, attempt: f"{int(attempt*64)}G",  # scales with the longest contig
        runtime=lambda wildcards, attempt: int(attempt * 60),
    params:
        batch_size=16,
        model_cfg=get_tiberius_model_cfg,
        softmask_param=get_tiberius_softmask_param,
    shell:
        "tiberius.py "
        "--genome {input.fasta} "
        "--model_cfg {params.model_cfg} "
        "--out {output.gtf} "
        "--batch_size {params.batch_size} "
        "{params.softmask_param} "
        "&> {log}"


rule expand_tiberius_model:
    input:
        "resources/tiberius_model_files/{tiberius_model}.tar.gz",
    output:
        directory("resources/tiberius_models/{tiberius_model}"),
    log:
        "logs/expand_tiberius_model/{tiberius_model}.log",
    shadow:
        "minimal"
    container:
        utils["debian"]
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    shell:
        "mkdir -p {output} && "
        "tar -zxf {input} -C {output} --strip-components 1 &> {log} && "
        "printf $(date -Iseconds) > {output}/TIMESTAMP"


rule download_tiberius_model:
    output:
        temp("resources/tiberius_model_files/{tiberius_model}.tar.gz"),
    log:
        "logs/download_tiberius_model/{tiberius_model}.log",
    retries: 3
    shadow:
        "minimal"
    container:
        utils["wget"]
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    params:
        model_url=lambda wildcards: tools_dict["tiberius"]["models"][
            wildcards.tiberius_model
        ],
    shell:
        "wget -O {output} {params.model_url} &> {log}"
