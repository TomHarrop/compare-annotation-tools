#!/usr/bin/env python3


# note, the BUSCO lineages need to be inside the Funannotate DB. This is done
# by symlinking them at runtime.
rule funannotate_setup:
    input:
        augustus=Path("resources", "augustus"),
    output:
        db=directory(Path("resources", "funannotate", "db")),
    params:
        dbs=tools_dict["funannotate"]["dbs"],
    container:
        tools_dict["funannotate"]["container"]
    shadow:
        "minimal"
    shell:
        "export AUGUSTUS_CONFIG_PATH={input.augustus} ; "
        "funannotate setup "
        "--database {output.db} "
        "-i {params.dbs} "


# just pulls the DB out of the container so it can be writable
rule funannotate_augustus_db:
    output:
        db=directory(Path("resources", "augustus")),
    container:
        tools_dict["funannotate"]["container"]
    shell:
        "cp -r /usr/local/config {output.db} "
