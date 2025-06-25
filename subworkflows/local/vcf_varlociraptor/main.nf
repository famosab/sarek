include { VARLOCIRAPTOR_CALLVARIANTS } from '../../../modules/nf-core/varlociraptor/callvariants/main'
include { VARLOCIRAPTOR_PREPROCESS as PREPROCESS_TUMOR } from '../../../modules/nf-core/varlociraptor/preprocess/main' 
include { VARLOCIRAPTOR_PREPROCESS as PREPROCESS_NORMAL } from '../../../modules/nf-core/varlociraptor/preprocess/main'  
include { VARLOCIRAPTOR_ESTIMATEALIGNMENTPROPERTIES as ALIGNMENTPROPERTIES_TUMOR     } from '../../../modules/nf-core/varlociraptor/estimatealignmentproperties/main' 
include { VARLOCIRAPTOR_ESTIMATEALIGNMENTPROPERTIES as ALIGNMENTPROPERTIES_NORMAL    } from '../../../modules/nf-core/varlociraptor/estimatealignmentproperties/main' 

workflow VCF_VARLOCIRAPTOR {

    take:
    tools                         // Mandatory, list of tools to apply
    cram                          // channel: [mandatory] cram
    fasta                         // channel: [mandatory] fasta
    fasta_fai                     // channel: [mandatory] fasta_fai
    ch_vcf

    main:
    // TODO: different routes for tumor_only, normal_only, tumor_and_normal

    ch_versions = Channel.empty()

    ch_scenario = Channel.fromPath("$projectDir/assets/varlociraptor_somatic_with_priors.yml", checkIfExists: true)

    // Estimate alignment properties
    ALIGNMENTPROPERTIES_TUMOR(
        // TODO: check order of channel where tumor and normal is
        cram.map{ meta, normal_cram, normal_crai, tumor_cram, tumor_crai -> [ meta, tumor_cram ] },
        fasta,
        fasta_fai
    )

    ALIGNMENTPROPERTIES_NORMAL(
        cram.map{ meta, normal_cram, normal_crai, tumor_cram, tumor_crai -> [ meta, normal_cram ] },
        fasta,
        fasta_fai
    )

    ch_versions = ch_versions.mix(ALIGNMENTPROPERTIES_TUMOR.out.versions)
    ch_versions = ch_versions.mix(ALIGNMENTPROPERTIES_NORMAL.out.versions)

    PREPROCESS_NORMAL(
        
    )

    PREPROCESS_TUMOR(

    )

    // scenario_list ("tumor", "normal")
    ch_vcf_for_callvariants = PREPROCESS_NORMAL.out.bcf
        .join(PREPROCESS_TUMOR.out.bcf)

    // TODO: check for reihenfolge

    VARLOCIRAPTOR_CALLVARIANTS(
        // PREPROCESS_NORMAL.out.bcf & PREPROCESS_TUMOR.out.bcf,
        ch_scenario,
        // scenario_list
    
    )

    // TODO: alias (status tumor or normal) & group (patient id) (welche samples werden zusammengefasst?)
    emit:
    // TODO nf-core: edit emitted channels
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}
