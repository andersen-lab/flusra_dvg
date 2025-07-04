process SAMTOOLS_DEPTH {
    tag "${meta.id} - ${referenceGene}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(bamFile)
    each referenceGene
    path reference

    output:
    path "*_depth.tsv", emit: tsv
    path "versions.yml", emit: versions

    script:
    def gene = referenceGene.split("\\|")[0]
    """
    samtools index ${bamFile}

    samtools \\
        depth \\
        --reference ${reference} \\
        -r \"${referenceGene}\" \\
        --threads ${task.cpus} \\
        -aa \\
        ${bamFile} \\
        > ${meta.id}_${gene}_depth.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def gene = referenceGene.split("\\|")[0]
    """
    touch ${meta.id}_${gene}_depth.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*version //; s/Please.*\$//')
    END_VERSIONS
    """
}
