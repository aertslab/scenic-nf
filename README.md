# SCENIC Nextflow pipeline using containers

A basic pipeline for running (py)SCENIC implemented in Nextflow.

## Requirements
    
* [Nextflow](https://www.nextflow.io/)
* A container system:
  * [Docker](https://docs.docker.com/)
    * Pre-built image from dockerhub: [aertslab/pyscenic:latest](https://cloud.docker.com/u/aertslab/repository/docker/aertslab/pyscenic).
    [See also here.](https://github.com/aertslab/pySCENIC#docker-and-singularity-images)
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
    --output = Name of the output loom file.
    --grn = GRN inference method, either "grnboost2" or "genie3" (optional, default: grnboost2)

## Running the pipeline on the example dataset

### Download testing dataset

Download a minimum set of SCENIC database files for a human dataset (approximately 75 MB).
This small test dataset takes approiximately 30s to run using 6 threads on a standard desktop computer.

    mkdir example && cd example/
    # Transcription factors:
    wget https://raw.githubusercontent.com/aertslab/containerizedGRNboost/master/example/input/allTFs_hg38.txt
    # Motif to TF annotation database:
    wget https://raw.githubusercontent.com/aertslab/scenic-nf/master/example/motifs.tbl
    # Ranking databases:
    wget https://raw.githubusercontent.com/aertslab/scenic-nf/master/example/genome-ranking.feather
    # Finally, get a small sample expression matrix (loom format):
    wget https://raw.githubusercontent.com/aertslab/scenic-nf/master/example/expr_mat.loom


### Running the example pipeline

#### Docker

    nextflow run aertslab/scenic-nf \
        -profile docker \
        --expr expr_mat.loom \
        --TFs allTFs_hg38.txt \
        --motifs motifs.tbl \
        --db *feather \
        -r loom

#### Singularity

    nextflow run aertslab/scenic-nf \
        -profile singularity \
        --expr expr_mat.loom \
        --TFs allTFs_hg38.txt \
        --motifs motifs.tbl \
        --db *feather \
        -r loom

## To run with extra reporting enabled

    nextflow run aertslab/scenic-nf -with-report report.html -with-timeline timeline.html -with-dag dag.png -profile [docker|singularity]




