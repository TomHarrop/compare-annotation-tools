#!/usr/bin/env python3


def funannotate_busco_lineages(wildcards):
    busco_lineage_paths = [
        Path("resources", "busco_databases", x) for x in all_busco_lineages
    ]
    return busco_lineage_paths


rule funannotate_setup:
    input:
        augustus=Path("resources", "augustus"),
        funannotate_busco_lineages=funannotate_busco_lineages,
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
        "&& "
        "for bl in {input.funannotate_busco_lineages} ; do "
        "   cp -r "
        "   $( readlink -f $bl ) "
        "   $( readlink -f {output.db} )/ ; "
        "done"


# just pulls the DB out of the container so it can be writable
rule funannotate_augustus_db:
    output:
        db=directory(Path("resources", "augustus")),
    container:
        tools_dict["funannotate"]["container"]
    shell:
        "cp -r /usr/local/config {output.db} "
