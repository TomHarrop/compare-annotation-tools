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
    tiberius_model: "Eudicotyledons"
```

Pass it to snakmake using the `--configfile` option:

```bash
snakemake \
    --configfile config.yaml
```

## TODO

- [ ] handle remote genomes
- [x] GPU resources - fill in the partitionflag and exclusive using yte
- [ ] collect stats
- [ ] implement annotation tools:
  - [ ] tiberius
    - [ ] add all the models
  - [x] helixer
  - [ ] annevo
  - [x] funannotate
