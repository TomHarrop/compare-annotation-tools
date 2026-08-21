## Annotations to abandon

### Funannotate

- [X] mPerGun1.1, qmEuaArma1.1 funannotate out of time after runtime=5760

### Braker

- [x] qmEuaArma1.1 braker GeneMark not enough hits
- [X] iyExoRobu1.1 braker out of time after runtime=4320

## Annotations to fix

### RepeatMasker

- [ ] **rm_target has a typo in the copy command**

- [X] fOphBen repeat masker output is corrupted.
    - fOphBen1.1 braker error, unexpected letter found in sequence /opt/ETP/bin/gmes/ProtHint/bin/proteins_from_gtf.pl: CCAGAAAATGGTGTTTCTTCTTCGACTTTTCATCATTTTCACCATTTANCAFFOLN
    - rm input (funannotate clean output) is fine
- [X] aCriSig and lsXanJohn1.1 clean_query ran out of mem with mem=64G
- [X] fApoMad1.1m
  - rm failed, need to handle:
  - FATAL ERROR: RepeatModeler giving up. One or more
batches failed!  Unfortunately this type of error
cannot be recovered from. Please submit the following
details to the feedback page at the repeatmasker
website:
  - **actually, the rm_model fail is handled. this didn't work because of this error:
    - `cp: error copying 'results/run/fApoMad1.1/repeatmasker/input_genome.fasta' to 'results/run/fApoMad1.1/input_genome.masked.fasta': Disk quota exceeded`
- [X] .2 results/run/rHetBin1.2/input_genome.masked.fasta is size 0
  - rerun

### Funannotate

- [X] bAcaMag1.2, mMacGis1.1, bEmbPic1.2,  exited funny (switch model)

### Braker

- [X] aTauPle1.2 braker mv failed, rerun

### annooddities

- [ ] fApoMad1.1
  - mikado fail, re-run to work out
    - .snakemake/shadow/tmpldwr6_c5/fApoMad1.1.mikado_tab_stats.log
    - TypeError: The exon data for agat-transcript-21970 should all be located on chromosome scaffold_102, but the providedexon data is on a different chromosome, scaffold_164. scaffold_164 Tiberius       exon    6679    6751    .       +       0       ID=agat-exon-246969;Parent=agat-transcript-21970
  - **actually mikado is failing on all Tiberius annotations**
- [X] could be a tiberius bug, re-run with latest container.
