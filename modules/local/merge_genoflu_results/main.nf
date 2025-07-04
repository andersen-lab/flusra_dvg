process MERGE_GENOFLU_RESULTS {
    tag "merge_results"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"

    input:
    path tsv_files
    path existing_results

    output:
    path "genoflu_results.tsv"
    path "versions.yml", emit: versions

    script:
    def existing_results_file = existing_results.name != "NO_FILE" ? "--existing_results ${existing_results}" : ""
    """    
    merge_genoflu.py \\
        --output_file genoflu_results.tsv \\
        ${existing_results_file}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch "${params.genoflu_results}"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
