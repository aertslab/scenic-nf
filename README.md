# SCENIC Nextflow pipeline using containers

A basic pipeline for running (py)SCENIC implemented in Nextflow.

## Requirements
    
* [Nextflow](https://www.nextflow.io/)
* [Docker](https://docs.docker.com/)
* From pySCENIC:
  * A locally-built Docker image, [see here](https://github.com/aertslab/pySCENIC#docker-and-singularity-images)

## Running the pipeline

To run the basic pipeline:

    nextflow run scenic-docker.nf

To run with extra reporting enabled:

    nextflow run scenic-docker.nf -with-report report.html -with-timeline timeline.html -with-dag dag.png

## Limitations

* Input databases and expression matrix are hard coded.


