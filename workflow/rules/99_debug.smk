#!/usr/bin/env Rscript


rule check_apptainer_environment:
    input:
        expand(Path("debug", "env.{export}.txt"), export=[True, False]),


# Troubleshooting rule for debugging cluster jobs
rule print_apptainer_environment:
    wildcard_constraints:
        export="|".join([str(True), str(False)]),
    output:
        Path("debug", "env.{export}.txt"),
    # resources:
    #     sbatch_export=lambda wildcards: (
    #         "APPTAINER_CLEANENV=true,APPTAINER_CONTAINALL=true,APPTAINER_WRITABLE_TMPFS=true"
    #         if wildcards.export
    #         else "APPTAINER_CLEANENV=,APPTAINER_CONTAINALL=false,APPTAINER_WRITABLE_TMPFS=false"
    #     ),
    container:
        config["utils"]["debian"]
    shell:
        "env &> {output}"
