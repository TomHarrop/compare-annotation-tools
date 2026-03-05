#!/usr/bin/env bash

preserve_output_on_timeout() {
    echo "RepeatModeler timed out"

    # Find the latest round directory that contains both consensi.fa and
    # families.stk with non-zero size.
    best_round=""
    best_mtime=0

    while IFS= read -r -d '' round_dir; do
        consensi="${round_dir}/consensi.fa"
        families="${round_dir}/families.stk"
        if [[ -s "${consensi}" && -s "${families}" ]]; then
            # Use the older of the two files as the round's completion time
            mtime_consensi="$(stat -c '%Y' "${consensi}")"
            mtime_families="$(stat -c '%Y' "${families}")"
            if (( mtime_consensi < mtime_families )); then
                round_mtime="${mtime_consensi}"
            else
                round_mtime="${mtime_families}"
            fi
            if (( round_mtime > best_mtime )); then
                best_mtime="${round_mtime}"
                best_round="${round_dir}"
            fi
        fi
    done < <(
        find "${fa_dir}" \
            -maxdepth 2 \
            -type d \
            -name "round-*" \
            -print0
    )

    if [[ -n "${best_round}" ]]; then
        cp "${best_round}/families.stk" "${stk_out}"
        cp "${best_round}/consensi.fa" "${fa_out}"

        cat << EOF > "${fa_dir}/WARNING.md"
RepeatModeler timed out.
Partial results from "${best_round}" have been copied:
"${best_round}/families.stk" -> "${stk_out}"
"${best_round}/consensi.fa" -> "${fa_out}"
EOF
    else
        # No complete round found; touch empty outputs so the
        # checkpoint can detect zero-size and skip masking.
        touch "${stk_out}"
        touch "${fa_out}"

        cat << EOF > "${fa_dir}/WARNING.md"
RepeatModeler timed out and no complete round results were found.
Empty output files have been created.
EOF
    fi
}

run_rm_model() {
    cd "${fa_dir}" || exit 1
    RepeatModeler \
        -database input_genome \
        -engine ncbi \
        -threads "${threads}" \
        &> "${log}"
}

export -f run_rm_model

# set aside 10 minutes to handle timeout gracefully
runtime_total_min=$(( "${snakemake_resources[runtime]}" ))
runtime_giveup_min=$(( runtime_total_min - 10 ))

export fa_dir="${snakemake_params[fa_dir]}"
export fa_out="${snakemake_output[fa]}"
export stk_out="${snakemake_output[stk]}"
export log="${snakemake_log[0]}"
export threads="${snakemake[threads]}"

status=0
timeout "${runtime_giveup_min}m" bash -c 'run_rm_model' || status=$?

if [[ $status -eq 124 ]]; then
    preserve_output_on_timeout
    exit 0
elif [[ $status -ne 0 ]]; then
    # RepeatModeler failed for a non-timeout reason (e.g. "No families identified")
    # Touch empty outputs so the checkpoint skips masking
    touch "${fa_out}"
    touch "${stk_out}"
    exit 0
fi

# RepeatModeler succeeded — ensure outputs exist at the expected paths
for f in "${fa_out}" "${stk_out}"; do
    if [[ ! -s "${f}" ]]; then
        basename_f="$(basename "${f}")"
        if [[ -s "${fa_dir}/${basename_f}" ]]; then
            cp "${fa_dir}/${basename_f}" "${f}"
        else
            touch "${f}"
        fi
    fi
done