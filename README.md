# SCENIC Nextflow pipeline using containers

A basic pipeline for running (py)SCENIC implemented in Nextflow.

## Requirements
    
* [Nextflow](https://www.nextflow.io/)
* A container system:
  * [Docker](https://docs.docker.com/)
    * From pySCENIC, a locally-built Docker image, [see here](https://github.com/aertslab/pySCENIC#docker-and-singularity-images)
  * [Singularity](https://www.sylabs.io/singularity/)
    * From singularity hub: shub://cflerin/pySCENIC:latest

## Running the pipeline

### Docker

To run the basic pipeline:

    nextflow run scenic.nf -profile docker

### Singularity

    nextflow run scenic.nf -profile singularity

### To run with extra reporting enabled

    nextflow run scenic.nf -with-report report.html -with-timeline timeline.html -with-dag dag.png -profile [docker|singularity]

## Limitations

* Input databases and expression matrix are hard coded.


