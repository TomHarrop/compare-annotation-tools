#!/usr/bin/env python3


def braker3_rnaseq_param(wildcards, input):
    try:
        return f"--bam {input.rnaseq}"
    except AttributeError as e:
        return ""


braker_result_files = tools_dict["braker3"]["result_files"]


rule braker3:
    input:
        unpack(annotation_tool_input_dict),
    output:
        expand(
            Path("results", "run", "{{genome}}", "braker3", "{result_file}"),
            result_file=braker_result_files,
        ),
    params:
        rnaseq=braker3_rnaseq_param,
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
        "&> {log}"


#################
# collect input #
#################
