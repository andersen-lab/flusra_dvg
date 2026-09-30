include { BWA_MEM } from '../../../modules/nf-core/bwa/mem/main'
include { IVAR_CONSENSUS } from '../../../modules/nf-core/ivar/consensus/main'
include { IVAR_VARIANTS } from '../../../modules/nf-core/ivar/variants/main'
include { SAMTOOLS_DEPTH } from '../../../modules/nf-core/samtools/depth/main'
include { GENOFLU } from '../../../modules/local/genoflu/main'
include { MERGE_GENOFLU_RESULTS } from '../../../modules/local/merge_genoflu_results/main'
include { COMBINE_SAMPLE_CONSENSUS } from '../../../subworkflows/local/utils_nfcore_flusra_pipeline'
include { DVG } from '../dvg/main.nf'

workflow PROCESS_SRA {
    take:
    sra_samples_ch

    main:

    ch_versions = Channel.empty()

    BWA_MEM(sra_samples_ch, params.reference)

    // Generate a tuple of genes from the reference fasta file
    Channel.from(readFastaHeaders(params.reference))
        .set { genes_ch }

    IVAR_CONSENSUS(
        BWA_MEM.out.bam,
        genes_ch,
        params.reference,
        params.consensus_threshold,
        params.consensus_min_depth,
    )

    COMBINE_SAMPLE_CONSENSUS(
        IVAR_CONSENSUS.out.consensus
    )

    GENOFLU(COMBINE_SAMPLE_CONSENSUS.out.grouped_fasta)

    MERGE_GENOFLU_RESULTS(
        GENOFLU.out.genoflu_results.collect(),
        params.genoflu_results,
    )

    SAMTOOLS_DEPTH(
        BWA_MEM.out.bam,
        genes_ch,
        params.reference,
    )

    BWA_MEM.out.bam
        .combine(
            genes_ch.map { header ->
                def gene = header.split("\\|")[0]
                [
                    gene,
                    header,
                    !params.gff_files.isEmpty() ? params.gff_files?.get(gene) ?: "${projectDir}/assets/NO_FILE" : "${projectDir}/assets/NO_FILE",
                ]
            }
        )
        .set { ch_ivar_variants_input }

    IVAR_VARIANTS(
        ch_ivar_variants_input,
        params.reference,
        params.variant_threshold,
        params.variant_min_depth,
    )

    // combine with sra_samples_ch with COMBINE_SAMPLE_CONSENSUS.out.grouped_fasta
    sra_samples_ch
        .concat(COMBINE_SAMPLE_CONSENSUS.out.grouped_fasta)
        .groupTuple(
            size: 2
        )
        .set { ch_combined_samples }

    ch_versions = ch_versions.mix(
        BWA_MEM.out.versions,
        IVAR_CONSENSUS.out.versions,
        IVAR_VARIANTS.out.versions,
        SAMTOOLS_DEPTH.out.versions,
        GENOFLU.out.versions,
        MERGE_GENOFLU_RESULTS.out.versions,
    )

    emit:
    ch_combined_samples = ch_combined_samples
    versions = ch_versions
}

def readFastaHeaders(fastaFile) {
    new File(fastaFile)
        .readLines()
        .findAll { it.startsWith(">") }
        .collect { it.substring(1) }
}
