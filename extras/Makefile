
test:
	snakemake \
		--configfile config/benchmark.yaml \
		--profile profiles/local \
		--keep-going


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