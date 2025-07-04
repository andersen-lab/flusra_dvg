//
// A subworkflow providing functions tailored for the analysis of milk samples using Freyja for the flusra/flusra pipeline.
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FREYJA_VARIANTS } from '../../../modules/nf-core/freyja/variants'
include { FREYJA_DEMIX } from '../../../modules/nf-core/freyja/demix'
include { MINIMAP2_ALIGN } from '../../../modules/nf-core/minimap2/align'


// Checks whether the provided depth file contains any depth values greater than zero.
def hasNonZeroDepth(depth_file) {
    return file(depth_file).readLines().any { it.split('\t')[-1].toInteger() > 0 }
}

workflow MILK_FREYJA {
    take:
    milk_samples_ch

    main:

    ch_versions = Channel.empty()

    MINIMAP2_ALIGN(milk_samples_ch, params.milk_reference)
    FREYJA_VARIANTS(MINIMAP2_ALIGN.out.bam, params.milk_reference)

    // Filter out samples with no depth
    ch_freyja_variants_demix = FREYJA_VARIANTS.out.variants.map { meta, variants, depth ->
        if (!file(depth).isEmpty() && hasNonZeroDepth(depth)) {
            return [meta, variants, depth]
        }
    }

    FREYJA_DEMIX(
        ch_freyja_variants_demix,
        params.milk_barcode,
        params.demix_autoadapt,
        params.demix_depthcutoff,
        params.demix_lineage_hierarchy,
    )

    ch_versions = ch_versions.mix(
        MINIMAP2_ALIGN.out.versions,
        FREYJA_VARIANTS.out.versions,
        FREYJA_DEMIX.out.versions,
    )

    emit:
    versions = ch_versions
}
