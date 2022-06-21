/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowPlatypusindelcalling.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }


// TODO: Write a pretty log here
log.info """\
INDEL CALLING WITH PLATYPUS - O D F Z - N F   P I P E L I N E
===================================

"""

params.reference='/Users/kubranarci/Desktop/Workflows/data_test/REF/17.fasta'

params.k_genome='/Users/kubranarci/Desktop/Workflows/data_test/References/ALL.wgs.phase1_integrated_calls.20101123.indels_plain.vcf.gz'
params.dbsnp_indel='/Users/kubranarci/Desktop/Workflows/data_test/References/00-All.INDEL.vcf.gz'
params.dbsnp_snv='/Users/kubranarci/Desktop/Workflows/data_test/References/00-All.SNV.vcf.gz'
params.exac_file='/Users/kubranarci/Desktop/Workflows/data_test/References/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz'
params.evs_file='/Users/kubranarci/Desktop/Workflows/data_test/References/ESP6500SI-V2-SSA137.updatedProteinHgvs.ALL.snps_indels.vcf.gz'
params.local_control_wgs='/Users/kubranarci/Desktop/Workflows/data_test/References/ExclusionList_2019_HIPO-PCAWG_MP_PL_WGS.INDELs.AFgt1.vcf.gz'
params.local_control_wes='/Users/kubranarci/Desktop/Workflows/data_test/References/ExclusionList_2019_H021_MP_PL_WES.INDELs.AFgt1.vcf.gz'
params.exome_capture_kit_bed_file='/Users/kubranarci/Desktop/Workflows/data_test/References/Agilent5withUTRs_plain.bed.gz'
params.genome_bed_file='/Users/kubranarci/Desktop/Workflows/data_test/References/Agilent5withUTRs_plain.bed.gz'
params.gnomed_genomes='/Users/kubranarci/Desktop/Workflows/data_test/References/gnomad.genomes.r2.1.sites.SNV-INDEL.vcf.gz'
params.gnomed_exomes='/Users/kubranarci/Desktop/Workflows/data_test/References/gnomad.exomes.r2.1.sites.SNV-INDEL.vcf.gz'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK }   from '../subworkflows/local/input_check'
include {PLATYPUS_RUNNER} from '../subworkflows/local/platypus_runner'
include {PLATYPUSINDELANNOTATION} from '../subworkflows/local/platypusindelannotation'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow PLATYPUSINDELCALLING {

    ch_versions = Channel.empty()
    ch_logs = Channel.empty()


//     SUBWORKFLOW: Read in samplesheet, validate and stage input files
//      TODO: validate files and check if control exists

    INPUT_CHECK (ch_input)
//    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)


//  TODO: I need to check if there is control file here, for no control there will be a different subworkflow!!

//

    //
    // SUBWORKFLOW: PLATYPUS
    //

    PLATYPUS_RUNNER(INPUT_CHECK.out.ch_sample)

    vcf_ch = PLATYPUS_RUNNER.out.ch_platypus_vcf_to_filter_gz
    ch_logs = ch_logs.mix(PLATYPUS_RUNNER.out.ch_platypus_log)
    ch_versions = ch_versions.mix(PLATYPUS_RUNNER.out.platypus_version)
    ch_versions= ch_versions.mix(PLATYPUS_RUNNER.out.bgzip_version)

    vcf_ch.view()


//    SUBWORKFLOW: INDEL_ANNOTATION
    PLATYPUSINDELANNOTATION(vcf_ch)


    // MODULE: MultiQC
    workflow_summary    = WorkflowPlatypusindelcalling.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
//    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
