#!/usr/bin/env nextflow

/*
20181213 CCF

To run:
nextflow run scenic-docker.nf -with-report report.html -with-timeline timeline.html -with-dag dag.png -resume
Cleanup:
rm dag.png* && rm report.html* && rm timeline.html* && rm -r work/

*/

params.expr = "/media/data/chris/nextflow-test/inputdata/expr_mat.tsv"
params.TFs = "/media/data/chris/docker/resources/allTFs_hg38.txt"
params.motifs = "/media/data/chris/docker/resources/motifs-v9-nr.hgnc-m0.001-o0.0.tbl"

// channel for SCENIC databases resources:
featherDB = Channel
    .fromPath( "/media/data/chris/docker/resources/hg19*mc9nr.feather" )
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
        --num_workers 6 \
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
        --output_type csv \
        --output reg.csv \
        --num_workers 6
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
        --num_workers 6
    """
}

AUCmat.copyTo('AUC-mtx_output.csv')

