#!/usr/bin/env bash

preserve_output_on_timeout() {
    echo "RM timed out"
    # TODO: is one of the fasta files complete? needs a longer run

    newest_masked_file="$(
        find "${fa_dir}" \
            -maxdepth 2 \
            -type f \
            -size +0c \
            -name "input_genome.fasta_batch*.masked" \
            -printf '%T@ %p\0' \
        | sort -z -nr \
        | head -z -n 1 \
        | cut -z -d' ' -f2-
    )"

    if [[ -n "${newest_masked_file}" ]]; then
        cp "${newest_masked_file}" "${fa_out}"
        for f in $misc; do touch $f ; done 

        cat << EOF > "${fa_dir}/WARNING.md"
RepeatMasker timed out.
The output file "${newest_masked_file}"
has been copied to
"${fa_out}"
EOF
    else
        exit 1
    fi
}

run_rm() {
    cd "${fa_dir}" || exit 1
    RepeatMasker \
        -engine ncbi \
        -pa "${threads}" \
        -lib "${lib}" \
        -gccalc -xsmall -gff -html \
        "${fa}" \
        &> "${log}"
}

export -f run_rm

# set aside 10 minutes to run rm.
runtime_total_min=$(( "${snakemake_resources[runtime]}" ))
runtime_giveup_min=$(( runtime_total_min - 10 ))

export fa_dir="${snakemake_params[fa_dir]}"
export fa_out="${snakemake_output[fa]}"
export fa="${snakemake_params[fa]}"
export lib="${snakemake_params[lib]}"
export log="${snakemake_log[0]}"
export misc="${snakemake_output[misc]}"
export threads="${snakemake_params[threads]}"

status=0
timeout "${runtime_giveup_min}m" bash -c 'run_rm' || status=$?

# If the inner timeout expired, timeout exits with 124.
if [[ $status -eq 124 ]]; then
    preserve_output_on_timeout
    exit 0
fi
