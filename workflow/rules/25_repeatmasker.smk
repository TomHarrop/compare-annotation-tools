#!/usr/bin/env python3


# currently failing because there are no repeats in the test dataset.

# RepeatScout/RECON discovery complete: 0 families found
# No families identified.  Perhaps the database is too small
# or contains overly fragmented sequences.

# This will need to be a checkpoint because sometimes zero repeats are found..
# Touch the output and check the size in the gather rule. If the size is zero,
# just use the output from clean_query as the "masked" genome. If it's not
# zero, use the output of rm_mask (i.e. trigger masking if there are repeats
# found.)
rule rm_model:
    input:
        multiext(
            Path(
                "results", "run", "{genome}", "repeatmasker", "input_genome"
            ).as_posix(),
            ".nhr",
            ".njs",
            ".nsq",
            ".translation",
        ),
        fa=Path("results", "run", "{genome}", "repeatmasker", "input_genome.fasta"),
    output:
        Path("results", "run", "{genome}", "repeatmasker", "input_genome-families.stk"),
        Path("results", "run", "{genome}", "repeatmasker", "input_genome-families.fa"),
    params:
        fa_dir=subpath(input.fa, parent=True),
    log:
        Path("logs", "{genome}", "repeatmasker", "rm_model.log").resolve(),
    benchmark:
        Path("logs", "{genome}", "repeatmasker", "rm_model.stats.jsonl").resolve()
    retries: 0
    threads: lambda wildcards, attempt: 16 * attempt
    resources:
        runtime=lambda wildcards, attempt: f"{int(1*(attempt))}d",
        mem=lambda wildcards, attempt: f"{int(8**(attempt+1))}GB",
    container:
        utils["tetools"]
    shell:
        "cd {params.fa_dir} || exit 1 && "
        "ls -lh . && "
        "RepeatModeler "
        "-database input_genome "
        "-engine ncbi "
        "-threads {threads} "
        "&> {log} "
        "&& ls -lhrt . "


rule rm_build:
    input:
        fa=Path("results", "run", "{genome}", "repeatmasker", "input_genome.fasta"),
    output:
        multiext(
            Path(
                "results", "run", "{genome}", "repeatmasker", "input_genome"
            ).as_posix(),
            ".nhr",
            ".nin",
            ".njs",
            ".nnd",
            ".nni",
            ".nog",
            ".nsq",
            ".translation",
        ),
    params:
        fa_dir=subpath(input.fa, parent=True),
    log:
        Path("logs", "{genome}", "repeatmasker", "rm_build.log").resolve(),
    benchmark:
        Path("logs", "{genome}", "repeatmasker", "rm_build.stats.jsonl").resolve()
    threads: 1
    resources:
        runtime=lambda wildcards, attempt: f"{int(1*(attempt))}d",
    container:
        utils["tetools"]
    shell:
        "cd {params.fa_dir} || exit 1 && "
        "BuildDatabase "
        "-name input_genome "
        "-dir ./ "
        "&> {log} "


rule clean_query:
    input:
        fa=Path("results", "run", "{genome}", "input_genome.fasta"),
    output:
        fa=Path("results", "run", "{genome}", "repeatmasker", "input_genome.fasta"),
    log:
        Path("logs", "{genome}", "repeatmasker", "clean_query.log"),
    benchmark:
        Path("logs", "{genome}", "repeatmasker", "clean_query.stats.jsonl")
    retries: 2
    threads: lambda wildcards, attempt: 16 * attempt
    resources:
        runtime=lambda wildcards, attempt: f"{int(1*(attempt))}d",
        mem=lambda wildcards, attempt: f"{int(8**(attempt+1))}GB",
    container:
        tools_dict["funannotate"]["container"]
    shell:
        "funannotate clean "
        "--exhaustive "
        "--input {input.fa} "
        "--out {output.fa} "
        "--cpus {threads} "
        "&> {log}"
