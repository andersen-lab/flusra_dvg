process IVAR_VARIANTS {
    tag "${meta.id} - ${referenceGene}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(bamFile), val(gene), val(referenceGene), path(gff)
    path reference
    val variant_threshold
    val variant_min_depth

    output:
    path "*_variants.tsv", emit: variants
    path "versions.yml", emit: versions

    script:
    def gff_file_arg = gff.name != "NO_FILE" ? "-g ${gff}" : ""
    """
    samtools index ${bamFile}

    samtools mpileup --reference ${reference} -r \"${referenceGene}\" -A -B -d 0 -aa -Q 0 ${bamFile} | ivar variants -p ${meta.id}_${gene}_variants -t ${variant_threshold} -m ${variant_min_depth} -r ${reference} ${gff_file_arg}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*version //; s/Please.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_${gene}_variants.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*version //; s/Please.*\$//')
    END_VERSIONS
    """
}
