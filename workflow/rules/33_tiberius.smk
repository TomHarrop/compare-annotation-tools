#!/usr/bin/env python3


def check_if_tiberius_model_requires_softmasking(model_path):
    model_name = model_path.name
    return model_name in tools_dict["tiberius"]["requires_softmasking"]


def get_tiberius_fasta(wildcards):
    model_path = get_tiberius_model(wildcards)
    requires_softmasking = check_if_tiberius_model_requires_softmasking(model_path)
    if requires_softmasking:
        return get_softmasked_fasta(wildcards)
    return get_unmasked_fasta(wildcards)


def get_tiberius_model(wildcards):
    tiberius_model = genomes_dict[wildcards.genome]["tiberius_model"]
    return Path("resources", "tiberius_models", tiberius_model)


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
    model_path = get_tiberius_model(wildcards)
    requires_softmasking = check_if_tiberius_model_requires_softmasking(model_path)
    return "" if requires_softmasking else "--no_softmasking"


rule tiberius:
    input:
        fasta=get_tiberius_fasta,
        model=get_tiberius_model,
    output:
        gtf=Path("results", "run", "{genome}", "tiberius", "tiberius.gtf"),
    params:
        batch_size=16,
        softmask_param=get_tiberius_softmask_param,
    log:
        Path("logs", "{genome}", "tiberius", "tiberius.log"),
    benchmark:
        Path("logs", "{genome}", "tiberius", "tiberius.stats.jsonl")
    resources:
        gpu=1,
        mem=lambda wildcards, attempt: f"{int(attempt*64)}G",  # scales with the longest contig
        runtime=lambda wildcards, attempt: int(attempt * 60),
    container:
        tools_dict["tiberius"]["container"]
    shell:
        "tiberius.py "
        "--genome {input.fasta} "
        "--model {input.model} "
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
