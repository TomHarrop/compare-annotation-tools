#!/usr/bin/env python3


# Make sure there are mapped reads in the bamfile. If there are no mapped reads,
# braker3 will try to run GeneMark-ETP, which will crash.
rule check_read_count:
    input:
        count_file=Path(
            "results", "run", "{genome}", "count_reads_in_bamfile.mapped_reads.txt"
        ),
    output:
        flagfile=Path("results", "run", "{genome}", "rnaseq_reads_ok"),
    run:
        logger.info(f"Counting mapped reads")
        with open(input.count_file, "rt") as f:
            read_count = int(f.read())
        if read_count == 0:
            logger.error(
                """
There are no mapped reads in bamfile.
This will cause GeneMark-ETP to crash.
Re-run the workflow without the bamfile.
"""
            )
        else:
            Path(output.flagfile).touch()


rule count_reads_in_bamfile:
    input:
        lambda wildcards: genomes_dict[wildcards.genome]["rnaseq"]
    output:
        flagfile=Path(
            "results", "run", "{genome}", "count_reads_in_bamfile.mapped_reads.txt"
        ),
    log:
        Path("logs", "{genome}", "count_reads_in_bamfile.log"),
    benchmark:
        Path("logs", "{genome}", "count_reads_in_bamfile.stats")
    container:
        utils["samtools"]
    shell:
        "samtools view -F4 -c {input} > {output} 2> {log}"
