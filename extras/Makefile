
export RCLONE_S3_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export RCLONE_S3_ENDPOINT="https://projects.pawsey.org.au"
export RCLONE_S3_PROVIDER="Ceph"
export RCLONE_S3_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

test:
	snakemake \
		--configfile config/benchmark.v2.yaml \
		--profile profiles/local \
		--keep-going \
		results/run/gyRhyGra1.2/tiberius/tiberius.gtf

test_braker_proteins:
	snakemake \
		--configfile config/test.yaml \
		--profile profiles/local \
		--keep-going --notemp \
		results/test_genome_without_rnaseq/braker3/stats/braker.gtf/short_summary.specific.busco.json/parsed.csv \
		results/test_genome_without_rnaseq/braker3/stats/braker.gtf/omark_summary.json/parsed.csv \
		results/test_genome_without_rnaseq/braker3/stats/braker.gtf/AnnoOddities.oddity_summary.txt/parsed.csv

graph:
	snakemake \
		--configfile config/test.yaml \
		--profile profiles/local \
		--rulegraph \
		--forceall \
		taxid2792576_target | \
		dot -Tpng > assets/graph.png

# 		results/run/taxid3240756/funannotate/predict_results/taxid3240756.gff3

test_softmasking:
	snakemake \
		--configfile config/benchmark.yaml \
		--profile profiles/local \
		results/run/taxid1592185/tiberius/tiberius.gtf -n