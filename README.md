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

- [ ] **REMOVE `05_smk_hack`**
  - Depends on this bug: https://github.com/snakemake/snakemake/issues/3916
- [x] handle remote genomes
  - [x] FIXME - currently assuming all downloaded genomes are fasta.gz
- [x] GPU resources - fill in the partitionflag and exclusive using yte
- [ ] collect stats
- [ ] collate resource usage
- [ ] implement annotation tools:
  - [x] tiberius
    - [x] add all the models
  - [x] helixer
    - [ ] collate RAM usage for resources
  - [ ] annevo
  - [x] funannotate
    - [ ] remove `--force` option for unmasked genomes
