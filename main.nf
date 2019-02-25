#!/usr/bin/env nextflow


println( "\n***\nParameters in use:")
params.each { println "${it}" }

// channel for SCENIC databases resources:
featherDB = Channel
    .fromPath( params.db )
    .collect() // use all files together in the ctx command

n = Channel.fromPath(params.db).count().get()
if( n==1 ) {
    println( "***\nWARNING: only using a single feather database:\n  ${featherDB.get()[0]}.\nTo include all database files using pattern matching, make sure the value for the '--db' parameter is enclosed in quotes!\n***\n" )
} else {
    println( "***\nUsing $n feather databases:")
    featherDB.get().each {
        println "  ${it}"
    }
    println( "***\n")
}

expr = file(params.expr)
tfs = file(params.TFs)
motifs = file(params.motifs)

process GRNinference {

    input:
    file TFs from tfs
    file exprMat from expr

    output:
    file 'adj.tsv' into GRN

    """
    pyscenic grn \
        --num_workers ${params.threads} \
        -o adj.tsv \
        --method ${params.grn} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        ${exprMat} \
        ${TFs}
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
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
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
    file params.output into AUCmat

    """
    pyscenic aucell \
        $exprMat \
        reg.csv \
        -o ${params.output} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        --num_workers ${params.threads}
    """
}

AUCmat.last().collectFile(storeDir:params.outdir)

