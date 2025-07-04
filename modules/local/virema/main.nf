process VIREMA {
    label 'process_medium', 'process_high_memory'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(fastq), path(fasta)

    output:
    tuple val(meta), path("virema_outputs/BED_Files/*_Virus_Recombination_Results.bed"), emit: recombinationBedFiles
    tuple val(meta), path("virema_outputs/*.bam"), emit: bamFiles
    tuple val(meta), path("virema_outputs/*.sam"), emit: samFiles
    path "virema_outputs/*.coverage-stats.txt"
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""
    """
    git clone https://github.com/andrewrouth/ViReMa.git --depth 1

    python ViReMa/ViReMa_0.32/ViReMa.py \\
        ${fasta} \\
        ${fastq} \\
        ${fastq}.sam \\
        ${args} \\
        --Output_Dir virema_outputs \\
        --Output_Tag ${fastq}.ViReMa \\
        -BAM \\
        -Stranded \\
        --Seed 20 \\
        --X 3 \\
        --MicroInDel_Length 30 \\
        --Defuzz 0 \\
        --p ${task.cpus} \\
        -BED12 \\
        --MaxIters 50 \\
        --Coverage_Offset 10 \\
        -Overwrite \\
        -FuzzEntry

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch *_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        ViReMa: \$(git -C ViReMa/ViReMa_0.32 rev-parse HEAD)
    END_VERSIONS
    """
}
