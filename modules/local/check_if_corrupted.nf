process CHECK_IF_CORRUPTED {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://kubran/odcf_platypusindelcalling:v1' :'kubran/odcf_platypusindelcalling:v1' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta),path("*.raw.vcf.gz"), path("*.raw.vcf.gz.tbi"), emit: vcf
    path("*.linesCorrupt")                                        , optional: true
    path("*.11")                                                  , optional: true
    path  "versions.yml"                                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def nocontrol = meta.iscontrol == '1' ? 'false': 'true'
    
// If there is control (iscontrol=1), isNoControlWorkflow is false

    """
    # Set TMPDIR to the current working directory
    export TMPDIR=\$PWD
    ls -l $vcf
    corrupted.sh -i $vcf -c $nocontrol
    (zcat $vcf | grep '#' ; zcat $vcf | grep -v '#' | sort -V -k1,2 -T \$TMPDIR) | bgzip -f > indel_${prefix}.raw.vcf.gz 

    tabix indel_${prefix}.raw.vcf.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tabix: \$(echo \$(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
        gzip: \$(echo \$(gzip --version 2>&1) | sed 's/^.*gzip //; s/ .*\$//')
    END_VERSIONS
    """
    
}
