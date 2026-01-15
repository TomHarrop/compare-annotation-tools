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
    resources:
        runtime=1,
        mem_mb=100,
        sbatch_export="APPTAINER_CLEANENV=,APPTAINER_CONTAINALL=false,APPTAINER_WRITABLE_TMPFS=false",
    container:
        config["utils"]["debian"]
    shell:
        "env &> {output}"
