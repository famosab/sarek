process VARLOCIRAPTOR_CALLVARIANTS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/varlociraptor:8.7.1--ha8ac579_0':
        'biocontainers/varlociraptor:8.7.1--ha8ac579_0' }"

    input:
    tuple val(meta), path(vcfs)
    path (scenario)
    val (scenario_aliases) // list of values ["tumor", "normal"]

    output:
    tuple val(meta), path("*.bcf"), emit: bcf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_called"

    //If we use a scenario file and if there is more than 1 normal vcf, then collect scenario_sample_name and normal vcf to scenario_sample_name_0=normal_vcf_0 scenario_sample_name_1=normal_vcf_1, etc
    //If we use a scenario file and if there is exactly 1 normal vcf, then scenario_sample_name=normal_vcf
    //Else do nothing
    def scenario_samples = vcfs instanceof List &&  vcfs.size() > 1 ? [scenario_aliases,vcfs].transpose().collect{"${it[0]}=${it[1]}"}.join(' ') : "${scenario_aliases}=${vcfs}"
    """
    varlociraptor call variants \\
        --output ${prefix}.bcf \\
        generic --scenario ${scenario} --obs ${scenario_samples} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        varlociraptor: \$(echo \$(varlociraptor --version 2>&1) | sed 's/^.*varlociraptor //; s/:.*\$//' )
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}_called"
    """
    touch ${prefix}.bcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        varlociraptor: \$(echo \$(varlociraptor --version 2>&1) | sed 's/^.*varlociraptor //; s/:.*\$//' )
    END_VERSIONS
    """
}
