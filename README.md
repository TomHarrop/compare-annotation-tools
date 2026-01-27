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

## Recommendations

### BUSCO lineage for `funannotate`

Choosing the right BUSCO lineage for `funannotate` (`--busco_db` option) seems
to be hit and miss. We start with the closest parent lineage, and keep trying
higher-level DBs until we find one that works.

Sometimes `funannotate` fails at the BUSCO step, with an error like this:

```
ERROR 69: /usr/local/bin/../share/glimmerhmm/train/score exited funny: 35584 at /usr/local/bin/trainGlimmerHMM line 445.
```

Sometimes it fails like this:

```
[Jan 28 12:29 AM]: Running BUSCO to find conserved gene models for training ab-initio predictors
[Jan 28 01:01 AM]: 0 valid BUSCO predictions found, validating protein sequences
```

Neither error happens every time for a given lineage so it's probably caused by
certain combinations of genome and lineage. It's possible to override the BUSCO
lineage for `funannotate` in the config, like this:

```yaml
  test_genome:
    busco_lineage: "embryophyta_odb10"
    fasta_file: "test-data/genome.fa.gz"
    taxon_id: 3702
    overrides:
      funannotate:
        busco_lineage: "viridiplantae_odb10"
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
