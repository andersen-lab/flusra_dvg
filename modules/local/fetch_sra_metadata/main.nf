process FETCH_SRA_METADATA {
    tag "Fetch SRA metadata"
    label "process_single"

    conda "${moduleDir}/environment.yml"

    input:
    val bioproject_id
    val email
    path sra_metadata_file
    path trimming_config
    val check_retracted

    output:
    path "*_updated.csv", optional: true
    path "*_to_process.tsv", optional: true, emit: new_samples
    path "versions.yml", emit: versions

    script:
    def trim_config = trimming_config.name != "NO_FILE" ? "--trimming_config ${trimming_config}" : ""
    def retracted = check_retracted ? "--check_retracted" : ""
    """
    fetch_sra_metadata.py \\
        --bioproject_ids "${bioproject_id}" \\
        --email ${email} \\
        --metadata ${sra_metadata_file} \\
        ${trim_config} \\
        ${retracted}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ${sra_metadata_file}_updated.csv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
