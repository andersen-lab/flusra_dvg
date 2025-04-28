//
// A subworkflow providing utility functions tailored for the flusra/flusra pipeline.
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FETCH_SRA_METADATA        } from '../../../modules/local/fetch_sra_metadata'
include { GROUP_FASTA             } from '../../../modules/local/group_fasta'
/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow PIPELINE_INITIALISATION {

    take:
    bioproject
    email
    sra_metadata_file

    main:

    FETCH_SRA_METADATA(bioproject, email, sra_metadata_file, params.trimming_config, params.check_retracted)

    FETCH_SRA_METADATA.out.new_samples.splitCsv(header: true, sep: '\t')
        .map { row ->
            meta = [
                id: row.Run.toString(),
                process_flag: row.process_flag.toBoolean(),
                milk_flag: row.is_milk.toBoolean(),
                trimming_flag: row.containsKey('global_trimming') && row.global_trimming
                            ? new groovy.json.JsonSlurper()
                                .parseText(row.global_trimming.replaceAll("'", '"'))
                            : null
            ]
            [meta, row.Run]
        }
        .set { samples_to_process }

    emit:
    samples_to_process = samples_to_process
}

/*
========================================================================================
    SUBWORKFLOW FOR PIPELINE COMPLETION
========================================================================================
*/

workflow COMBINE_SAMPLE_CONSENSUS {
    take:
    samples_to_process

    main:
    samples_to_process.groupTuple(
            size: 8,
            remainder: false,
        ).set { grouped_fasta }
    GROUP_FASTA(
        grouped_fasta
    )

    emit:
    grouped_fasta = GROUP_FASTA.out.fasta
}

workflow PIPELINE_COMPLETION {
    main:

    //
    // Completion summary
    //
    workflow.onComplete {
        completionSummary()
    }

    workflow.onError {
        log.error "Pipeline failed."
    }
}

/*
========================================================================================
    FUNCTIONS
========================================================================================
*/
//
// Print pipeline summary on completion
//
def completionSummary() {
    if (workflow.success) {
        if (workflow.stats.ignoredCount == 0) {
            log.info "[$workflow.manifest.name]\033[0;32m Pipeline completed successfully\033[0m-"
        } else {
            log.info "[$workflow.manifest.name]\033[0;33m Pipeline completed successfully, but with errored process(es)\033[0m-"
        }
    } else {
        log.info "[$workflow.manifest.name]\033[0;31m Pipeline completed with errors\033[0m-"
    }
}
