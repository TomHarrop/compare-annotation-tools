#!/usr/bin/env python3


def braker3_rnaseq_param(wildcards, input):
    try:
        return f"--bam {input.rnaseq}"
    except AttributeError as e:
        return ""


def get_orthodb_division(wildcards):
    orthodb_division = genomes_dict[wildcards.genome]["orthodb_division"]
    return Path(f"resources/orthodb_division/{orthodb_division}.fa")


braker_result_files = tools_dict["braker3"]["result_files"]
additional_braker_files = [
    "braker.aa",
    "braker.codingseq",
    "genome_header.map",
    "what-to-cite.txt",
]

# only generated if RNAseq is included, so they can't be used for subsequent
# steps
rnaseq_dependent_braker_files = [
    "bam_header.map",
    "hintsfile.gff",
]


rule braker3:
    input:
        unpack(annotation_tool_input_dict),
        fasta=get_softmasked_fasta,
        orthodb=get_orthodb_division,
    output:
        temp(
            expand(
                Path("results", "run", "{{genome}}", "braker3", "{result_file}"),
                result_file=braker_result_files + additional_braker_files,
            )
        ),
    params:
        rnaseq=braker3_rnaseq_param,
        outdir=subpath(output[0], parent=True),
    log:
        log=Path("logs", "{genome}", "braker3", "braker3.log"),
        braker=Path("results", "run", "{genome}", "braker3", "braker.log"),
    benchmark:
        Path("logs", "{genome}", "braker3", "braker3.stats.jsonl")
    threads: 128
    resources:
        runtime=int(3 * 24 * 60),
        mem="230G",
    container:
        tools_dict["braker3"]["container"]
    shadow:
        "minimal"
    shell:
        "braker.pl "
        "--genome={input.fasta} "
        "--prot_seq={input.orthodb} "
        "--gff3 "
        "--threads {threads} "
        "{params.rnaseq} "
        "--species={wildcards.genome} "
        "&> {log.log} "
        "&& mv braker/* {params.outdir}/ "


rule expand_orthodb_division:
    input:
        "resources/orthodb_division_files/{orthodb_division}.fa.gz",
    output:
        fasta="resources/orthodb_division/{orthodb_division}.fa",
        timestamp="resources/orthodb_division/{orthodb_division}.fa.TIMESTAMP",
    log:
        "logs/expand_orthodb_division/{orthodb_division}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    shadow:
        "minimal"
    container:
        utils["debian"]
    shell:
        "gunzip -c {input} > {output.fasta} 2> {log} && "
        "printf $(date -Iseconds) > {output.timestamp}"


rule download_orthodb_division:
    output:
        temp("resources/orthodb_division_files/{orthodb_division}.fa.gz"),
    params:
        model_url=lambda wildcards: tools_dict["braker3"]["orthodb_divisions"][
            wildcards.orthodb_division
        ],
    log:
        "logs/download_orthodb_division/{orthodb_division}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 3
    shadow:
        "minimal"
    container:
        utils["wget"]
    shell:
        "wget -O {output} {params.model_url} &> {log}"
