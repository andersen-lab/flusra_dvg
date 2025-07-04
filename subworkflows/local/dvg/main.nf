include { VIREMA } from '../../../modules/local/virema/main.nf'
include { COMBINE_UNSTRANDED_ANNOTATIONS } from '../../../modules/local/combine_unstranded_annotations/main.nf'
include { BEDTOOLS_GENOME_COVERAGE_BED } from '../../../modules/nf-core/bedtools/genomeCoverageBed/main.nf'
include { DVG_FREQ_CALC } from '../../../modules/local/dvg_freq_calc/main.nf'

workflow DVG {
    take:
    samples_ch

    main:
    // samples_ch = [meta, [[fastqs], fasta]]
    // convert to a tuple of [meta, fastqs, fasta]
    samples_ch
        .map { meta, files ->
            def fastqs = files[0]
            def fasta = files[1]
            [meta, fastqs, fasta]
        }
        .branch {
            single: it[1] instanceof Path
            paired: it[1] instanceof List
        }
        .set { branched_samples_ch }


    // TODO: Add support for single-end reads
    // single_end_ch = branched_samples_ch.single.map { meta, fastq, fasta -> [meta, fastq, fasta] }

    paired_end_ch = branched_samples_ch.paired.flatMap { meta, fastqs, fasta ->
        fastqs.collect { fastq -> [meta, fastq, fasta] }
    }

    virema_input_ch = paired_end_ch

    VIREMA(
        virema_input_ch
    )
}
