
process INDEL_EXTRACTION {
    tag "$meta.id"
    label 'process_low'

    conda     (params.enable_conda ? "$baseDir/assets/perlenvironment.yml" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    '' :
    'kubran/perl_annotate:v0' }"

    publishDir params.outdir+'/indelextraction'                                    , mode: 'copy'

    input:
    tuple val(meta), file(ch_vcf), file(ch_vcf_i)

    output:
    tuple val(meta), path('*functional.vcf.gz'), path('*functional.vcf.gz.tbi')   , emit: vcf
    tuple val(meta), path('*.functional_var_count.txt')                           , emit: functional_var
    path  "versions.yml"                                                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def outname   = "${meta.id}.functional.vcf"
    def outnamegz = "${meta.id}.functional.vcf.gz"

    def somatic_indels_vcf            ="${meta.id}_somatic_indels_conf_${params.min_confidence_score}_to_10.vcf"
    def somatic_functional_indel_vcf  ="${meta.id}_somatic_functional_indels_conf_${params.min_confidence_score}_to_10.vcf"
    def somatic_ncRNA_indel_vcf       ="${meta.id}_somatic_ncRNA_indels_conf_${params.min_confidence_score}_to_10.vcf"
    def germline_functional_indel_vcf ="${meta.id}_germline_functional_indels_conf_${params.min_confidence_score}_to_10.vcf"

    """
    indel_extractor_v1.pl --infile=$ch_vcf --somout=$somatic_indels_vcf --funcout=$somatic_functional_indel_vcf --ncout=$somatic_ncRNA_indel_vcf \\
        --germlineout=$germline_functional_indel_vcf --minconf=${params.min_confidence_score} ${params.add_filter_opt}
    bgzip -c $somatic_indels_vcf > $outnamegz
    tabix $outnamegz
    cat $somatic_functional_indel_vcf | tail -n +2 | wc -l | cut -f1 -d " " > ${meta.id}.functional_var_count.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    perl: \$(echo \$(perl --version 2>&1) | sed 's/^.*perl //; s/Using.*\$//')
    tabix: \$(echo \$(tabix -h 2>&1) | sed 's/^.*tabix //; s/Using.*\$//')
    END_VERSIONS
    """
}