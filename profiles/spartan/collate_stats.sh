#!/bin/bash

#SBATCH --job-name=collate_stats
#SBATCH --time=0-10
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --output=collate_stats.slurm.out
#SBATCH --error=collate_stats.slurm.err

set -eux

module load GCCcore/13.3.0
module load Python/3.12.3 Apptainer/1.4.5

dir="results/collated_stats"
template="collated_stats.$(date -I).XXXXXXXX.csv"

stats_file="$(mktemp -u -p "${dir}" "${template}")"

apptainer exec \
	docker://ghcr.io/tomharrop/r-containers:r2u_24.04_cv1 \
	Rscript workflow/scripts/collate_stats.R \
	"${stats_file}"
