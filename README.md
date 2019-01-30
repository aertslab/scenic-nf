# SCENIC Nextflow pipeline using containers

A basic pipeline for running (py)SCENIC implemented in Nextflow.

## Requirements
    
* [Nextflow](https://www.nextflow.io/)
* A container system:
  * [Docker](https://docs.docker.com/)
    * Pre-build image from dockerhub: [aertslab/pyscenic:latest](https://cloud.docker.com/u/aertslab/repository/docker/aertslab/pyscenic).
  * [Singularity](https://www.sylabs.io/singularity/)
    * Pre-built image from singularity hub: [aertslab/pySCENIC:latest](https://www.singularity-hub.org/collections/2033).


## Parameters: input files and databases

Requires the same support files as [pySCENIC](https://github.com/aertslab/pySCENIC).
These can be passed as command line parameters to nextflow.

    --expr = expression matrix, (tsv format)

    --TFs = file containing transcription factors, one per line

    --motifs = Motif annotation database, tbl format.

    --db = Ranking databases, feather format. If using a glob pattern to select multiple database files, this parameter must be enclosed in quotes (i.e. --db "/path/to/dbs/hg19*feather").

    --threads = Number of threads to use.

    --output = Name of the output file (csv).

    --grn = GRN inference method, either "grnboost2" or "genie3" (optional, default: grnboost2)


## Running the pipeline on the example dataset

### Download testing dataset

Download a minimum set of SCENIC database files for a human dataset (approximately 1GB):

    cd scenic-nf
    mkdir example

    # Transcription factors:
    wget https://raw.githubusercontent.com/aertslab/containerizedGRNboost/master/example/input/allTFs_hg38.txt -P example/

    # Motif to TF annotation database:
    wget https://raw.githubusercontent.com/aertslab/scenic-nf/master/example/motifs.tbl -P example/

    # Ranking databases:
    wget https://raw.githubusercontent.com/aertslab/scenic-nf/master/example/genome-ranking.feather -P example/

    # Finally, get a small sample expression matrix:
    wget https://raw.githubusercontent.com/aertslab/containerizedGRNboost/master/example/input/expr_mat.txt.gz -P example/
    gunzip -c example/expr_mat.txt.gz > example/expr_mat.tsv


### Running the example pipeline

#### Docker

    nextflow run aertslab/scenic-nf \
        -profile docker \
        --expr example/expr_mat.tsv \
        --TFs example/allTFs_hg38.txt \
        --motifs example/motifs-v9-nr.hgnc-m0.001-o0.0.tbl \
        --db "example/*feather" \
        -r master

#### Singularity

    nextflow run aertslab/scenic-nf \
        -profile singularity \
        --expr example/expr_mat.tsv \
        --TFs example/allTFs_hg38.txt \
        --motifs example/motifs-v9-nr.hgnc-m0.001-o0.0.tbl \
        --db "example/*feather" \
        -r master


## To run with extra reporting enabled

    nextflow run aertslab/scenic-nf -with-report report.html -with-timeline timeline.html -with-dag dag.png -profile [docker|singularity]




