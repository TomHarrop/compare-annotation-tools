#!/usr/bin/env python3


rule atol_qc_annotation:
    input:
        annotation=Path("results", "{genome}", "{tool}", "annotation", "{result_file}"),
        fasta=Path("results", "run", "{genome}", "input_genome.fasta"),
        busco_lineage=get_busco_lineage,
        db="data/omark/LUCA.h5",
        ete_ncbi_db="data/omark/ete/taxa.sqlite",
    output:
        [
            Path(
                "results",
                "{genome}",
                "{tool}",
                "qc",
                "{result_file}",
                "atol_qc_annotation",
                x,
            ).as_posix()
            for x in qc_tools_dict["atol_qc_annotation"]["result_files"]
        ],
    params:
        lineage_dataset=subpath(input.busco_lineage, basename=True),
        lineages_path=subpath(input.busco_lineage, parent=True),
        mem_gb=lambda wildcards, resources: int(resources.mem_mb / 1000),
        outdir=subpath(output[0], parent=True),
        taxid=select_taxid,
    log:
        Path("logs", "{genome}", "atol_qc_annotation", "{tool}.{result_file}.log"),
    benchmark:
        Path("logs", "{genome}", "atol_qc_annotation", "{tool}.{result_file}.stats.jsonl")
    threads: 16
    resources:
        mem="64GB",
        runtime=120,
    container:
        qc_tools_dict["atol_qc_annotation"]["container"]
    shell:
        "atol-qc-annotation "
        "--threads {threads} "
        "--mem {params.mem_gb} "
        "--fasta {input.fasta} "
        "--annot {input.annotation} "
        "--lineage_dataset {params.lineage_dataset} "
        "--lineages_path {params.lineages_path} "
        "--db {input.db} "
        "--taxid {params.taxid} "
        "--ete_ncbi_db {input.ete_ncbi_db} "
        "--outdir {params.outdir} "
        "--logs {params.outdir}/logs "
        "&> {log}"


rule annooddities:
    input:
        annotation=Path("results", "{genome}", "{tool}", "annotation", "{result_file}"),
        fasta=Path("results", "run", "{genome}", "input_genome.fasta"),
    output:
        archive=Path(
            "results",
            "{genome}",
            "{tool}",
            "qc",
            "{result_file}",
            "annooddities",
            "AnnoOddities.tar.gz",
        ),
        gff=Path(
            "results",
            "{genome}",
            "{tool}",
            "qc",
            "{result_file}",
            "annooddities",
            "AnnoOddities.gff",
        ),
        stats=Path(
            "results",
            "{genome}",
            "{tool}",
            "qc",
            "{result_file}",
            "annooddities",
            "AnnoOddities.combined_statistics.json",
        ),
        summary=Path(
            "results",
            "{genome}",
            "{tool}",
            "qc",
            "{result_file}",
            "annooddities",
            "AnnoOddities.oddity_summary.txt",
        ),
    params:
        outdir=subpath(output["archive"], parent=True),
    log:
        Path("logs", "{genome}", "annooddities", "{tool}.{result_file}.log"),
    benchmark:
        Path("logs", "{genome}", "annooddities", "{tool}.{result_file}.stats.jsonl")
    resources:
        mem="32GB",
        runtime=60,
    container:
        qc_tools_dict["annooddities"]["container"]
    shadow:
        "minimal"
    shell:
        "annooddities "
        "--genome_fasta {input.fasta} "
        "--gff3_file {input.annotation} "
        "--output_prefix {wildcards.genome} "
        "&> {log} "
        "&& "
        "cp {wildcards.genome}.AnnoOddities.combined_statistics.json {output.stats} "
        "&& "
        "cp {wildcards.genome}.AnnoOddities.gff {output.gff} "
        "&& "
        "cp {wildcards.genome}.AnnoOddities.oddity_summary.txt {output.summary} "
        "&& "
        'tar -cvf {output.archive} -I "gzip --best" '
        "./{wildcards.genome}.* ./oddity_files &>> {log}"
