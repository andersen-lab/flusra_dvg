process FREYJA_DEMIX {
    tag "${meta.id}"
    label 'process_high', 'process_low_memory'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(variant), path(depth)
    path barcode
    val demix_autoadapt
    val demix_depthcutoff
    path demix_lineage_hierarchy

    output:
    path "*.demixed", emit: demixed
    path "versions.yml", emit: versions

    script:
    def autoadapt = demix_autoadapt ? "--autoadapt" : ""
    def depth_cutoff = demix_depthcutoff ? "--depthcutoff ${demix_depthcutoff}" : ""
    def lineage_hierarchy = demix_lineage_hierarchy.name != "NO_FILE" ? "--lineageyml ${demix_lineage_hierarchy}" : ""
    """
    freyja demix \\
        ${variant} \\
        ${depth} \\
        ${autoadapt} \\
        ${lineage_hierarchy} \\
        ${depth_cutoff} \\
        --barcodes ${barcode} \\
        --output ${meta.id}.demixed


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.demixed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freyja: \$(echo \$(freyja --version 2>&1) | sed 's/^.*version //' )
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
