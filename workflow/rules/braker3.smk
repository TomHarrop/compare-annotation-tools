#!/usr/bin/env python3


def braker3_rnaseq_param(wildcards, input):
    try:
        return f"--bam {input.rnaseq}"
    except AttributeError as e:
        return ""


braker_result_files = tools_dict["braker3"]["result_files"]
additional_braker_files = [
    "braker.aa",
    "braker.codingseq",
    "braker.log",
    "genome_header.map",
    "what-to-cite.txt",
]

# only generated if RNAseq is included, so they can't be used for subsequent
# steps
rnaseq_dependent_braker_files = [
    "bam_header.map",
    "hintsfile.gff",
]


def run_a_function(input):
    raise ValueError(input)


rule braker3:
    input:
        unpack(annotation_tool_input_dict),
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
        Path("logs", "{genome}", "braker3", "braker3.log"),
    benchmark:
        Path("logs", "{genome}", "braker3", "braker3.stats")
    threads: 32
    resources:
        runtime=int(3 * 24 * 60),
        mem_mb=int(256e3),
    container:
        tools_dict["braker3"]["container"]
    shadow:
        "minimal"
    shell:
        "braker.pl "
        "--genome={input.fasta} "
        "--gff3 "
        "--threads {threads} "
        "{params.rnaseq} "
        "--species={wildcards.genome} "
        "&> {log} "
        "&& mv braker/* {params.outdir}/ "
