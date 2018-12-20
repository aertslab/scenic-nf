#!/usr/bin/env nextflow

/*
20181213 CCF

To run:
nextflow run scenic-docker.nf -with-report report.html -with-timeline timeline.html -with-dag dag.png -resume
Cleanup:
rm dag.png* && rm report.html* && rm timeline.html* && rm -r work/

*/

params.expr = "/media/data/chris/docker/inputdata/expr_mat_subset.tsv"
params.TFs = "/media/data/chris/docker/resources/allTFs_hg38.txt"
params.motifs = "/media/data/chris/docker/resources/motifs-v9-nr.hgnc-m0.001-o0.0.tbl"
params.db = "/media/data/chris/docker/resources/hg19*mc9nr.feather"

params.threads = 6

// channel for SCENIC databases resources:
featherDB = Channel
    .fromPath( params.db )
    .collect() // use all files together in the ctx command

expr = file(params.expr)
tfs = file(params.TFs)
motifs = file(params.motifs)


process GRNboost {

    input:
    file TFs from tfs
    file exprMat from expr

    output:
    file 'adj.tsv' into GRN

    """
    pyscenic grnboost \
        --num_workers ${params.threads} \
        -o adj.tsv \
        $exprMat \
        $TFs
    """
}

process i_cisTarget {

    input:
    file exprMat from expr
    file 'adj.tsv' from GRN
    file feather from featherDB
    file motif from motifs

    output:
    file 'reg.csv' into regulons

    """
    pyscenic ctx \
        adj.tsv \
        ${feather} \
        --annotations_fname ${motif} \
        --expression_mtx_fname ${exprMat} \
        --mode "dask_multiprocessing" \
        --output reg.csv \
        --num_workers ${params.threads} \
    """
}

process AUCell {

    input:
    file exprMat from expr
    file 'reg.csv' from regulons

    output:
    file 'auc.csv' into AUCmat

    """
    pyscenic aucell \
        $exprMat \
        reg.csv \
        -o auc.csv \
        --num_workers ${params.threads}
    """
}

AUCmat.copyTo('AUC-mtx_output.csv')

