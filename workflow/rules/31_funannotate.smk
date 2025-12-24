#!/usr/bin/env python3

predict_result_files = [
    "{genome}.cds-transcripts.fa",
    "{genome}.discrepency.report.txt",
    "{genome}.error.summary.txt",
    "{genome}.gbk",
    "{genome}.gff3",
    "{genome}.mrna-transcripts.fa",
    "{genome}.parameters.json",
    "{genome}.proteins.fa",
    "{genome}.scaffolds.fa",
    "{genome}.stats.json",
    "{genome}.tbl",
    "{genome}.validation.txt",
]


rule collect_funannotate_result:
    localrule: True
    input:
        gff=Path(
            "results",
            "run",
            "{genome}",
            "funannotate",
            "predict_results",
            "{genome}.gff3",
        ),
    output:
        gff=Path("results", "run", "{genome}", "funannotate", "funannotate.gff3"),
    shell:
        "cp {input} {output}"


# This doesn't work with containall, writable-tmps and cleanenv. Also, BUSCO
# needs the full path to the DB.
rule funannotate_predict:
    input:
        unpack(annotation_tool_input_dict),
        db=rules.funannotate_setup.output,
        gm_key=Path("data", "gm_key_64"),
        busco_lineage=get_busco_lineage,
    output:
        list(
            Path("results", "run", "{genome}", "funannotate", "predict_results", x)
            for x in predict_result_files
        ),
    params:
        busco_seed_species=lambda wildcards: genomes_dict[wildcards.genome][
            "augustus_dataset_name"
        ],
        busco_lineage_name=subpath(input.busco_lineage, basename=True),
        db_path=lambda wildcards, input: Path(
            subpath(input.db[0], parent=True)
        ).resolve(),
        min_training_models=config["parameters"]["busco_min_training_models"],
        outdir=subpath(output[0], ancestor=2),
    log:
        Path("logs", "{genome}", "funannotate", "funannotate_predict.log"),
    benchmark:
        Path("logs", "{genome}", "funannotate", "funannotate_predict.stats")
    threads: 32
    resources:
        runtime=60,
        mem="64G",
    container:
        tools_dict["funannotate"]["container"]
    shell:
        'header_length=$( grep "^>" {input.fasta} | wc -L ) ; '
        "cp {input.gm_key} ${{HOME}}/.gm_key ; "
        "funannotate predict "
        "--input {input.fasta} "
        "--out {params.outdir} "
        '--species "{wildcards.genome}" '
        '--busco_seed_species "{params.busco_seed_species}" '
        "--busco_db {params.busco_lineage_name} "
        '--header_length "${{header_length}}" '
        "--database {params.db_path} "
        "--cpus {threads} "
        "--optimize_augustus "
        "--organism other "
        "--repeats2evm "
        "--max_intronlen 50000 "
        "--min_training_models {params.min_training_models} "
        "&> {log}"


# TODO, only run this if there is RNAseq data
# rule funannotate_train:
#     input:
#         Path(run_tmpdir, "gm_key"),
#         fasta=Path(run_tmpdir, "genome.fa"),
#         left=rnaseq_r1,
#         right=rnaseq_r2,
#         gm_key=Path(run_tmpdir, "gm_key"),
#     output:
#         gff=Path(
#             outdir,
#             "funannotate",
#             "training",
#             "funannotate_train.transcripts.gff3",
#         ),
#     params:
#         fasta=lambda wildcards, input: Path(input.fasta).resolve(),
#         wd=lambda wildcards, output: Path(
#             output.gff
#         ).parent.parent.resolve(),
#     log:
#         Path(logdir, "funannotate_train.log").resolve(),
#     threads: workflow.cores
#     container:
#         funannotate
#     shell:
#         "cp {input.gm_key} ${{HOME}}/.gm_key ; "
#         "funannotate train "
#         "--input {params.fasta} "
#         "--out {params.wd} "
#         "--left {input.left} "
#         "--right {input.right} "
#         "--stranded RF "
#         "--max_intronlen 10000 "
#         f'--species "{species_name}" '
#         f"--header_length {header_length} "
#         "--cpus {threads} "
#         " &> {log}"
