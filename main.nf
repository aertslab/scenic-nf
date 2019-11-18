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
nbRuns = params.nb_runs

// UTILS
def runName = { it.getName().split('__')[0] }

process GRNinference {
    cache 'deep'
    cpus params.threads

    input:
    each runId from 1..nbRuns
    file TFs from tfs
    file exprMat from expr

    output:
    file "run_${runId}__adj.tsv" into grn, grn_save

    """
    pyscenic grn \
        --num_workers ${task.cpus} \
        -o "run_${runId}__adj.tsv" \
        --method ${params.grn} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        ${exprMat} \
        ${TFs}
    """
}

process cisTarget {
    cache 'deep'
    cpus params.threads

    input:
    file exprMat from expr
    file adj from grn
    file feather from featherDB
    file motif from motifs

    output:
    file "${runName(adj)}__reg.csv" into regulons, regulons_save

    """
    pyscenic ctx \
        ${adj} \
        ${feather} \
        --annotations_fname ${motif} \
        --expression_mtx_fname ${exprMat} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        --mode "dask_multiprocessing" \
        --output "${runName(adj)}__reg.csv" \
        --num_workers ${task.cpus} \
    """
}

process AUCell {
    cache 'deep'
    cpus params.threads

    input:
    file exprMat from expr
    file reg from regulons

    output:
    file "${runName(reg)}__${params.output}" into auc_mat

    """
    pyscenic aucell \
        $exprMat \
        $reg \
        -o ${runName(reg)}__${params.output} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        --num_workers ${task.cpus}
    """
}

def save = {
    (full, run, filename, ext) = (it.getName() =~ /(.+)__(.+)\.(.+)/)[0]
    if( params.nb_runs==1 ) {
        outDir = file( params.outdir )
    } else if( params.nb_runs>1 ) {
        outDir = file( params.outdir+"/$run" )
    }
    result = outDir.mkdirs()
    println result ? "$run finished." : "Cannot create directory: $outDir"
    Channel
        .fromPath(it)
        .collectFile(name: "${filename}.${ext}", storeDir: outDir)
}

grn_save.subscribe {
    save(it)
}
regulons_save.subscribe {
    save(it)
}
auc_mat.subscribe {
    save(it)
}
