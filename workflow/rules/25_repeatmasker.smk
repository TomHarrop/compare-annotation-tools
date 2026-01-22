#!/usr/bin/env python3


def get_rm_genome(wildcards):
    model_output = checkpoints.rm_model.get(**wildcards).output["fa"]
    if Path(model_output).stat().st_size == 0:
        return Path("results", "run", "{genome}", "repeatmasker", "input_genome.fasta")
    else:
        return Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome.fasta.masked"
        )


rule rm_target:
    input:
        get_rm_genome,
    output:
        fa=Path("results", "run", "{genome}", "input_genome.masked.fasta"),
    shell:
        "cp {input} {output}"


# TODO: Oops. I put the timeout here but it should be in the modelling steps. Re-do.
rule rm_mask:
    input:
        cons=Path(
            "results",
            "run",
            "{genome}",
            "repeatmasker",
            "input_genome-families.fa.classified",
        ),
        fa=Path("results", "run", "{genome}", "repeatmasker", "input_genome.fasta"),
    output:
        misc=multiext(
            Path(
                "results", "run", "{genome}", "repeatmasker", "input_genome.fasta"
            ).as_posix(),
            ".cat.gz",
            ".masked",
            ".out.gff",
            ".out.html",
            ".out",
            ".tbl",
        ),
        fa=Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome.fasta.masked"
        ),
    params:
        fa_dir=subpath(input.fa, parent=True),
        fa=subpath(input.fa, basename=True),
        lib=subpath(input.cons, basename=True),
        threads=lambda wildcards, threads: int(threads // 4),
    log:
        Path("logs", "{genome}", "repeatmasker", "rm_mask.log").resolve(),
    benchmark:
        Path("logs", "{genome}", "repeatmasker", "rm_mask.stats.jsonl").resolve()
    threads: lambda wildcards, attempt: 16 * attempt
    resources:
        runtime=lambda wildcards, attempt: f"{int(1*(attempt))}d",
        mem=lambda wildcards, attempt: f"{int(8**(attempt+1))}GB",
    container:
        utils["tetools"]
    script:
        "../scripts/rm_mask.sh"


rule rm_classify:
    input:
        stk=Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome-families.stk"
        ),
        fa=Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome-families.fa"
        ),
    output:
        cons=Path(
            "results",
            "run",
            "{genome}",
            "repeatmasker",
            "input_genome-families.fa.classified",
        ),
    params:
        fa_dir=subpath(input.fa, parent=True),
        consensi=subpath(input.fa, basename=True),
        stockholm=subpath(input.stk, basename=True),
    log:
        Path("logs", "{genome}", "repeatmasker", "rm_classify.log").resolve(),
    benchmark:
        Path("logs", "{genome}", "repeatmasker", "rm_classify.stats.jsonl").resolve()
    retries: 0
    threads: lambda wildcards, attempt: 16 * attempt
    resources:
        runtime=lambda wildcards, attempt: f"{int(1*(attempt))}d",
        mem=lambda wildcards, attempt: f"{int(8**(attempt+1))}GB",
    container:
        utils["tetools"]
    shell:
        "cd {params.fa_dir} || exit 1 ; "
        "RepeatClassifier "
        "-threads {threads} "
        "-consensi {params.consensi} "
        "-stockholm {params.stockholm} "
        "&> {log}"


# This needs to be a checkpoint because sometimes zero repeats are found. ("No
# families identified.  Perhaps the database is too small or contains overly
# fragmented sequences.") Touch the output and check the size in the gather
# rule. If the size is zero, just use the output from clean_query as the
# "masked" genome. If it's not zero, use the output of rm_mask (i.e. trigger
# masking if there are repeats found.)
checkpoint rm_model:
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
        stk=Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome-families.stk"
        ),
        fa=Path(
            "results", "run", "{genome}", "repeatmasker", "input_genome-families.fa"
        ),
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
    # NASTY! ignore RM fails
    shell:
        "cd {params.fa_dir} || exit 1 && "
        "RepeatModeler "
        "-database input_genome "
        "-engine ncbi "
        "-threads {threads} "
        "&> {log} "
        "|| true ; "
        "for f in {output}; do touch $( basename $f ) ; done ;"


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
