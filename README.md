# Compare annotation tools

Run a set of different annotation tools on a genome and get standardised
metrics on the results.

## Usage

Specify the input genomes in YAML, e.g.

```yaml config/test.yaml
genomes:
  my_genome:
    fasta_file: "test-data/genome.fa.gz"
    taxon_id: 3702
    lineage: "embryophyta_odb10"
    rnaseq: "test-data/RNAseq.bam"
    augustus_dataset_name: "cacao"
```

Run with snakmake:

```bash
snakemake \
--profile profiles/local \
--configfile config/test.yaml
```

## TODO

- [ ] handle remote genomes
- [ ] implement annotation tools:
  - [ ] tiberius
  - [ ] helixer
  - [ ] annevo
  - [ ] funannotate
