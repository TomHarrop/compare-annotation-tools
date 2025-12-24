#!/usr/bin/env python3

from functools import cache

busco_directory_url = "https://busco-data.ezlab.org/v5/data"
busco_manifest_path = "file_versions.tsv"


@cache
def get_lineage_hash(wildcards):
    manifest = get_my_manifest(wildcards)
    return manifest["hash"]


@cache
def get_lineage_url(wildcards):
    # e.g.
    # https://busco-data.ezlab.org/v5/data/lineages/vertebrata_odb10.2024-01-08.tar.gz
    manifest = get_my_manifest(wildcards)
    return f"{busco_directory_url}/lineages/{wildcards.busco_lineage}.{manifest['date']}.tar.gz"


@cache
def get_my_manifest(wildcards):
    my_lineage = wildcards.busco_lineage
    manifest = read_manifest(wildcards)
    return manifest[my_lineage]


def read_manifest(wildcards):
    manifest = checkpoints.download_busco_manifest.get(**wildcards).output["manifest"]
    lineage_to_hash = {}
    with open(manifest) as f:
        for line in f:
            line_split = line.strip().split("\t")
            if line_split[4] == "lineages":
                lineage_to_hash[line_split[0]] = {
                    "date": line_split[1],
                    "hash": line_split[2],
                }
    return lineage_to_hash


# these go into the funannotate DB folder so they can be used directly from FA.
rule expand_busco_lineage_files:
    input:
        Path("resources", "busco_lineage_files", "{busco_lineage}.tar.gz"),
    output:
        busco_lineage=directory(
            Path("resources", "funannotate", "db", "{busco_lineage}")
        ),
    log:
        Path("logs", "expand_busco_lineage_files", "{busco_lineage}.log"),
    group:
        "busco"
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    shadow:
        "minimal"
    container:
        utils["debian"]
    shell:
        "mkdir -p {output.busco_lineage} && "
        "tar -zxf {input} -C {output.busco_lineage} --strip-components 1 &> {log} && "
        "printf $(date -Iseconds) > {output.busco_lineage}/TIMESTAMP"


rule download_busco_lineage_files:
    input:
        Path("resources", "busco_lineage_files", "file_versions.tsv"),
    output:
        temp(Path("resources", "busco_lineage_files", "{busco_lineage}.tar.gz")),
    params:
        lineage_url=get_lineage_url,
        lineage_hash=get_lineage_hash,
    log:
        Path("logs", "download_busco_lineage_files", "{busco_lineage}.log"),
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 3
    shadow:
        "minimal"
    container:
        utils["wget"]
    shell:
        "wget -O {output} {params.lineage_url} &> {log} && "
        "printf '%s %s' {params.lineage_hash}  {output} | md5sum -c - &>> {log}"


checkpoint download_busco_manifest:
    output:
        manifest=Path("resources", "busco_lineage_files", "file_versions.tsv"),
    params:
        busco_manifest_url=f"{busco_directory_url}/{busco_manifest_path}",
    log:
        Path("logs", "download_busco_manifest.log"),
    container:
        utils["wget"]
    shell:
        "wget {params.busco_manifest_url} -O {output} &> {log}"
