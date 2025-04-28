process GENOFLU {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(merged_fasta)

    output:
    path "*_stats.tsv", emit: genoflu_results
    path "versions.yml", emit: versions

    script:
    """
    genoflu.py -f ${merged_fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genoflu: \$(genoflu.py --version 2>&1)
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch *_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genoflu: \$(genoflu.py --version 2>&1)
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}
