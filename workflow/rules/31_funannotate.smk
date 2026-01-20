#!/usr/bin/env python3


def funannotate_rnaseq_param(wildcards, input):
    try:
        return f"--rna_bam {Path(input.rnaseq).resolve()}"
    except AttributeError as e:
        return ""


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
# needs the full path to the DB. Since it has trouble with the environment, we
# log that to an env file before we start.
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
        predict_misc=directory(Path("results", "run", "{genome}", "funannotate", "predict_misc")),
    params:
        busco_lineage_name=subpath(input.busco_lineage, basename=True),
        busco_seed_species=lambda wildcards: genomes_dict[wildcards.genome][
            "augustus_dataset_name"
        ],
        db_path=lambda wildcards, input: Path(
            subpath(input.db[0], parent=True)
        ).resolve(),
        fasta=lambda wildcards, input: Path(input.fasta).resolve(),
        min_training_models=config["parameters"]["busco_min_training_models"],
        outdir=lambda wildcards, output: Path(subpath(output[0], ancestor=2)).resolve(),
        rnaseq=funannotate_rnaseq_param,
    log:
        log=Path("logs", "{genome}", "funannotate", "funannotate_predict.log"),
        env=Path("logs", "{genome}", "funannotate", "funannotate_predict.env"),
    benchmark:
        Path("logs", "{genome}", "funannotate", "funannotate_predict.stats.jsonl")
    threads: 128
    resources:
        mem="230G",
        runtime=int(3 * 24 * 60),
    container:
        tools_dict["funannotate"]["container"]
    shell:
        "env &> {log.env} && "
        "mkdir -p {output.predict_misc}/tmp_opt_{wildcards.genome} && " # see https://github.com/nextgenusfs/funannotate/pull/1149
        'header_length=$( grep "^>" {input.fasta} | wc -L ) ; '
        "cp {input.gm_key} ${{HOME}}/.gm_key ; "
        "funannotate predict "
        '--busco_seed_species "{params.busco_seed_species}" '
        '--header_length "${{header_length}}" '
        '--species "{wildcards.genome}" '
        "--busco_db {params.busco_lineage_name} "
        "--cpus {threads} "
        "--database {params.db_path} "
        "--input {params.fasta} "
        "--max_intronlen 50000 "
        "--min_training_models {params.min_training_models} "
        "--optimize_augustus "
        "--organism other "
        "--out {params.outdir} "
        "--repeats2evm "
        "{params.rnaseq} "
        "&> {log.log}"
        # FIXME - this is to ignore unmasked genomes


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
