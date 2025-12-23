#!/usr/bin/env python3


include: "funannotate_setup.smk"


# this doesn't work with containall, writable-tmps and cleanenv.
rule funannotate_predict:
    input:
        unpack(annotation_tool_input_dict),
        db=Path("resources", "funannotate", "db"),
        gm_key=Path("data", "gm_key_64"),
        busco_lineage=select_busco_lineage,
    output:
        gff=Path("results", "run", "{genome}", "funannotate", "funannotate.gff3"),
    params:
        min_training_models=200,
        busco_seed_species=lambda wildcards: genomes_dict[wildcards.genome][
            "augustus_dataset_name"
        ],
        busco_lineage_name=subpath(input.busco_lineage, basename=True),
        wd=subpath(output.gff, parent=True),
    log:
        Path("logs", "{genome}", "funannotate", "funannotate_predict.log"),
    benchmark:
        Path("logs", "{genome}", "funannotate", "funannotate_predict.stats")
    threads: 32
    resources:
        runtime=60,
        mem="64G"
    container:
        tools_dict["funannotate"]["container"]
    shadow:
        "shallow"
    shell:
        'header_length=$( grep "^>" {input.fasta} | wc -L ) ; '
        'ln -s "$( readlink -f {input.busco_lineage} )" "{input.db}/" || true ; '
        "cp {input.gm_key} ${{HOME}}/.gm_key ; "
        "funannotate predict "
        "--input {input.fasta} "
        "--out {params.wd} "
        '--species "{wildcards.genome}" '
        '--busco_seed_species "{params.busco_seed_species}" '
        "--busco_db {params.busco_lineage_name} "
        '--header_length "${{header_length}}" '
        "--database {input.db} "
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
