#!/usr/bin/env nextflow

include { softwareVersionsToYAML } from './subworkflows/local/utils_nfcore_flusra_pipeline'
include { FLUSRA } from './workflows/flusra'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_flusra_pipeline'
include { PIPELINE_COMPLETION } from './subworkflows/local/utils_nfcore_flusra_pipeline'

workflow {
    ch_versions = Channel.empty()

    if (params.bioproject) {
        PIPELINE_INITIALISATION(params.bioproject, params.email, params.metadata)
        ch_versions = ch_versions.mix(PIPELINE_INITIALISATION.out.versions)
    }
    else {
        log.info("Skipping BioProject fetch as no BioProject ID provided")
    }

    if (!params.only_fetch) {
        if (params.bioproject && PIPELINE_INITIALISATION.out.samples_to_process) {
            FLUSRA(PIPELINE_INITIALISATION.out.samples_to_process)
            ch_versions = ch_versions.mix(FLUSRA.out.versions)
        }
        else if (params.samples_to_process) {
            Channel.fromPath(params.samples_to_process)
                .splitCsv(header: true, sep: '\t')
                .map { row ->
                    def meta = [
                        id: row.Run.toString(),
                        process_flag: row.process_flag.toBoolean(),
                        milk_flag: row.is_milk.toBoolean(),
                        trimming_flag: row.containsKey('global_trimming') && row.global_trimming
                            ? new groovy.json.JsonSlurper().parseText(row.global_trimming.replaceAll("'", '"'))
                            : null,
                    ]
                    [meta, row.Run]
                }
                .set { samples_ch }

            FLUSRA(samples_ch)
            ch_versions = ch_versions.mix(FLUSRA.out.versions)
        }
        else {
            log.info("No additional SRA accessions to process")
        }
    }
    else {
        log.info("Skipping SRA download and processing")
    }

    softwareVersionsToYAML(ch_versions).collectFile(
        storeDir: "${params.outdir}/pipeline_info",
        name: 'flusra_software_' + 'versions.yml',
        sort: true,
        newLine: true,
    )

    PIPELINE_COMPLETION()
}
