#!/usr/bin/env python3

funnanotate_db_files = [
    "funannotate-db-info.txt",
    "funannotate.repeat.proteins.fa",
    "funannotate.repeat.proteins.fa.tar.gz",
    "funannotate.repeats.reformat.fa",
    "repeats.dmnd",
    "uniprot.dmnd",
    "uniprot.release-date.txt",
    "uniprot_sprot.fasta",
]

funannotate_db_dirs = ["trained_species"]


# note, the BUSCO lineages need to be inside the Funannotate DB. This is done
# by symlinking them at runtime.
rule funannotate_setup:
    input:
        augustus=Path("resources", "augustus"),
    output:
        list(
            directory(Path("resources", "funannotate", "db", x))
            for x in funannotate_db_dirs
        ),
        list(Path("resources", "funannotate", "db", x) for x in funnanotate_db_files),
    params:
        dbs=tools_dict["funannotate"]["dbs"],
        db_dir=subpath(output[0], parent=True),
    log:
        Path("logs", "funannotate_setup.log"),
    container:
        tools_dict["funannotate"]["container"]
    shadow:
        "minimal"
    shell:
        "export AUGUSTUS_CONFIG_PATH={input.augustus} ; "
        "funannotate setup "
        "--database {params.db_dir} "
        "-i {params.dbs} "
        "&> {log}"


# just pulls the DB out of the container so it can be writable
rule funannotate_augustus_db:
    output:
        db=directory(Path("resources", "augustus")),
    container:
        tools_dict["funannotate"]["container"]
    shell:
        "cp -r /usr/local/config {output.db} "
