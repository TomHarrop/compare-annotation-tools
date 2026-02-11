
test:
	snakemake \
		--configfile config/test.yaml \
		--profile profiles/local \
		--keep-going


graph:
	snakemake \
		--configfile config/test.yaml \
		--profile profiles/local \
		--rulegraph |
		dot -Tpng > graph.png


# 		results/run/taxid3240756/funannotate/predict_results/taxid3240756.gff3
