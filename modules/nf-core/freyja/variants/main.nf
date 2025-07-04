process FREYJA_VARIANTS {
    tag "${meta.id}"
    label 'process_high', 'process_low_memory'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(bamFile)
    path reference

    output:
    tuple val(meta), path("*_variants.tsv"), path("*_depth.tsv"), emit: variants
    path "versions.yml", emit: versions

    script:
    """
    samtools index ${bamFile}

    freyja variants \\
        ${bamFile} \\
        --variants ${meta.id}_variants.tsv \\
        --depths ${meta.id}_depth.tsv \\
        --ref ${reference}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_variants.tsv
    touch ${meta.id}_depth.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
