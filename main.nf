#!/usr/bin/env nextflow


println( "\n***\nParameters in use:")
params.each { println "${it}" }

// channel for SCENIC databases resources:
motifDbs = Channel
    .fromPath( params.motif_dbs )
    .collect() // use all files together in the ctx command

n = Channel.fromPath(params.motif_dbs).count().get()
if( n==1 ) {
    println( "***\nWARNING: only using a single feather database:\n  ${motifDbs.get()[0]}.\nTo include all database files using pattern matching, make sure the value for the '--db' parameter is enclosed in quotes!\n***\n" )
} else {
    println( "***\nUsing $n feather databases:")
    motifDbs.get().each {
        println "  ${it}"
    }
    println( "***\n")
}

expr = file(params.expr)
tfs = file(params.TFs)
motifs = file(params.motif_tf_annotation)
// tracks = file(params.track_tf_annotation)
nbRuns = params.nb_runs

ctxMaskDropouts = params.ctx_mask_dropouts
ctxMaskDropoutsTag = ''
if(ctxMaskDropouts == 'no') {
    ctxMaskDropoutsTag = '_nodom'
}

// Resources limits
_maxForks = params.max_forks
maxCpus = params.threads

// UTILS
def runName = { it.getName().split('__')[0] }

if(params.parallel_framework == 'dask') {
    process dask_GRNinference {
        cache 'deep'

        clusterOptions "-l nodes=1:ppn=${params.threads} -l pmem=2gb -l walltime=${params.qsub_walltime_hours}:00:00 -A ${params.qsubaccount}"

        maxForks _maxForks
        cpus maxCpus

        input:
        each runId from 1..nbRuns
        file TFs from tfs
        file exprMat from expr

        output:
        file "run_${runId}__adj.tsv" into grn, grnSave

        """
        pyscenic grn \
            --num_workers ${params.threads} \
            -o "run_${runId}__adj.tsv" \
            --method ${params.grn} \
            --cell_id_attribute ${params.cell_id_attribute} \
            --gene_attribute ${params.gene_attribute} \
            ${exprMat} \
            ${TFs}
        """
    }
}

if(params.parallel_framework == 'multiprocessing_pool') {
    process multiprocessingPool_GRNinference {
        cache 'deep'

        clusterOptions "-l nodes=1:ppn=${params.threads} -l pmem=2gb -l walltime=${params.qsub_walltime_hours}:00:00 -A ${params.qsubaccount}"

        maxForks _maxForks
        cpus maxCpus

        input:
        each runId from 1..nbRuns
        file TFs from tfs
        file exprMat from expr

        output:
        file "run_${runId}__adj.tsv" into grn, grnSave

        """
        python /ddn1/vol1/staging/leuven/stg_00002/lcb/dwmax/documents/aertslab/GitHub/scenic-nf/bin/grnboost2_without_dask.py \
            --output "run_${runId}__adj.tsv" \
            --num_workers ${params.threads} \
            --seed ${runId} \
            --cell_id_attribute ${params.cell_id_attribute} \
            --gene_attribute ${params.gene_attribute} \
            ${exprMat} \
            ${TFs}
        """
    }
}

process motif_cisTarget {

    maxForks _maxForks
    cpus maxCpus

    cache 'deep'

    clusterOptions "-l nodes=1:ppn=${params.threads} -l pmem=2gb -l walltime=${params.qsub_walltime_hours}:00:00 -A ${params.qsubaccount}"

    input:
    file exprMat from expr
    file adj from grn
    file motifDb from motifDbs
    file motif from motifs

    output:
    file "${runName(adj)}__motif_reg${ctxMaskDropoutsTag}.csv" into motifRegulons, motifRegulonsSave

    """
    pyscenic ctx \
        ${adj} \
        ${motifDb} \
        --annotations_fname ${motif} \
        --expression_mtx_fname ${exprMat} \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        --mode "dask_multiprocessing" \
        --[mask_dropouts] "no" \
        --output "${runName(adj)}__motif_reg${ctxMaskDropoutsTag}.csv" \
        --num_workers ${params.threads} \
    """
}

process motif_AUCell {

    maxForks _maxForks
    cpus maxCpus

    cache 'deep'

    clusterOptions "-l nodes=1:ppn=${params.threads} -l pmem=1gb -l walltime=1:00:00 -A ${params.qsubaccount}"

    input:
    file exprMat from expr
    file reg from motifRegulons

    output:
    file "${runName(reg)}__motif${ctxMaskDropoutsTag}_${params.output}" into motifAUCMatrix

    """
    pyscenic aucell \
        $exprMat \
        $reg \
        -o "${runName(reg)}__motif${ctxMaskDropoutsTag}_${params.output}" \
        --cell_id_attribute ${params.cell_id_attribute} \
        --gene_attribute ${params.gene_attribute} \
        --num_workers ${params.threads}
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

grnSave.subscribe { 
    save(it) 
}
motifRegulonsSave.subscribe { 
    save(it) 
}
motifAUCMatrix.subscribe { 
    save(it) 
}
