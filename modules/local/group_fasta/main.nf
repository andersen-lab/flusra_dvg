process GROUP_FASTA {
    tag "${meta.id}"
    label 'process_single'

    input:
    tuple val(meta), path(fasta_files)

    output:
    tuple val(meta), path("*_grouped.fa"), emit: fasta

    script:
    """
    cat ${fasta_files} > ${meta.id}_grouped.fa
    """
}
