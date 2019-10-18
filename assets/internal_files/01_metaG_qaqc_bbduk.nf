#!/usr/bin/env nextflow

params.reads = "/home/li49pol/data/Projects/Probst_MG/Nextseq_MG/01_raw/*_R{1,2}.fastq.gz"
params.output_dir = "$HOME/scratch/Nextseq_MG"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs }

process bbduk_qaqc {
    tag {pair_id}
    storeDir "${params.output_dir}/02_QAQC"

    cpus 4

    input:
    set pair_id, file(reads) from read_pairs

    output:
    set pair_id, file("*.fastq") into qaqc_results
    file "${pair_id}.stats.txt"

    script:

    """
    bbduk.sh -Xmx1g \
        in1=${reads[0]} \
        in2=${reads[1]} \
        out1=${reads[0].baseName} \
        out2=${reads[1].baseName} \
        stats=${pair_id}.stats.txt \
        ref=$ADAPTERS \
        threads=${task.cpus} \
        ktrim=r \
        qtrim=rl \
        trimq=20 \
        minlen=50 \
        k=23 \
        mink=11 \
        hdist=1 \
    """
}
