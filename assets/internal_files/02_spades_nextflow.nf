#!/usr/bin/env nextflow

params.reads = "$HOME/data/Projects/example_metaGs/02_qaqc/*_{1,2}.fastq"
params.output_dir = "$HOME/data/Projects/example_metaGs/03_Assembly"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs }

process metaspades {
    tag {pair_id}
    publishDir "${params.output_dir}", mode: 'copy'

    cpus 10

    input:
    set pair_id, file(reads) from read_pairs

    output:  
    set pair_id, file("${pair_id}/*") into spades_assembly

    script:
    """
    spades.py --meta -o ${pair_id} -1 ${reads[0]} -2 ${reads[1]} -t ${task.cpus} \
    -m 350 --tmp-dir ~/scratch/
    """
}