

[![GitHub Actions CI Status](https://github.com/kubranarci/nf-core-platypusindelcalling/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/platypusindelcalling/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/kubranarci/nf-core-platypusindelcalling/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/platypusindelcalling/actions?query=workflow%3A%22nf-core+linting%22)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.3-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg)](https://sylabs.io/docs/)

<p align="center">
    <img title="nf-platypusindelcalling workflow" src="docs/images/nf-platypusindelcalling.png" width=30%>
</p>


## Introduction

**nf-platypusindelcalling**:A Platypus-based insertion/deletion-detection workflow with extensive quality control additions.  The workflow is based on DKFZ - ODCF OTP Indel Calling Pipeline.

For now, this workflow is only optimal to work in ODCF Cluster. The config file (conf/dkfz_cluster.config) can be used as an example. Running Annotation, DeepAnnotation, Filter and Tinda steps are optinal and can be turned off using [runIndelAnnotation, runIndelDeepAnnotation, runIndelVCFFilter, runTinda] parameters sequentialy.  

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies.

This nextflow pipeline is the transition of [DKFZ-ODCF/IndelCallingWorkflow] (https://github.com/DKFZ-ODCF/IndelCallingWorkflow). 

<!-- TODO nf-core: Add full-sized test dataset and amend the paragraph below if applicable -->

The Indel workflow was in the pan-cancer analysis of whole genomes (PCAWG) and can be cited with the following publication:

Pan-cancer analysis of whole genomes.
The ICGC/TCGA Pan-Cancer Analysis of Whole Genomes Consortium.
Nature volume 578, pages 82–93 (2020).
DOI 10.1038/s41586-020-1969-6


## Pipeline summary

<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

1. Platypus ([`Platypus`](https://www.well.ox.ac.uk/research/research-groups/lunter-group/lunter-group/platypus-a-haplotype-based-variant-caller-for-next-generation-sequence-data))
   : Platypus tool is used to call variants using local realignmnets and local assemblies. It can detect SNPs, MNPs, short indels, replacements, deletions up to several kb. It can be both used with WGS and WES. The tool has been thoroughly tested on data mapped with Stampy and BWA.
2. Basic Annotations: In-house scripts to annotate with several databases like gnomAD, dbSNP, and ExAC.
3. ANNOVAR ([`Annovar`](https://annovar.openbioinformatics.org/en/latest/))
   : annotate_variation.pl is used to annotate variants. The tool makes classifications for intergenic, intogenic, nonsynoymous SNP, frameshift deletion or large-scale duplication regions.
4. Reliability and confidation annotations: It is an optional step (--runIndelAnnotation) for Mapability, hiseq, selfchain and repeat regions checks for reliability and confidence of those scores.
5. INDEL Deep Annotation: It is an optional step (runIndelDeepAnnotation) for number of extra indel annotations like enhancer, cosmic, mirBASE, encode databases.
6. Filtering: It is an optional step (runIndelVCFFilter)for only applies for the tumor samples with no-control.
7. Checks Sample Swap: Canopy Based Clustering and Bias Filter


## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.10.3`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/))

3. Download the pipeline and test it on a minimal dataset with a single command:

   git clone https://github.com/kubranarci/nf-platypusindelcalling.git

  before run do this to bin directory, make it runnable!:

  ```console
  chmod +x bin/*
  ```

   ```console
   nextflow run main.nf -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   
4. Start running your own analysis!

   <!-- TODO nf-core: Update the example "typical command" below used to run the pipeline -->

   ```console
   nextflow run nf-core/platypusindelcalling --input samplesheet.csv --outdir <OUTDIR> --profile <docker/singularity/institute>
   ```
## Samplesheet columns

**sample**: The sample name will be tagged to the job

**tumor**: The path to the tumor file

**control**: The path to the control file, if there is no control will be kept blank.

## Data Requirements

All VCF and BED files need to be indexed with tabix and should be in the same folder!

[This section is for further]


## Documentation

**TODO**
The nf-core/platypusindelcalling pipeline comes with documentation about the pipeline [usage](https://nf-co.re/platypusindelcalling/usage), [parameters](https://nf-co.re/platypusindelcalling/parameters) and [output](https://nf-co.re/platypusindelcalling/output).


## Credits

nf-core/platypusindelcalling was originally written by Kuebra Narci kuebra.narci@dkfz-heidelberg.de.

The pipeline is originally written in workflow management language Roddy. [Inspired github page] (https://github.com/DKFZ-ODCF/IndelCallingWorkflow)

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#platypusindelcalling` channel](https://nfcore.slack.com/channels/platypusindelcalling) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use  nf-core/platypusindelcalling for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:
