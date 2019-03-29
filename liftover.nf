#!/usr/bin/env nextflow

/*================================================================
The MORETT LAB presents...

  The gnomAD liftover pipeline

- A genome coordinates convertion tool

==================================================================
Version: 0.0.6
Project repository: https://github.com/Iaguilaror/nf-gnomAD-liftover
==================================================================
Authors:

- Bioinformatics Design
 Israel Aguilar-Ordonez (iaguilaror@gmail)

- Bioinformatics Development
 Israel Aguilar-Ordonez (iaguilaror@gmail)

- Nextflow Port
 Israel Aguilar-Ordonez (iaguilaror@gmail)

=============================
Pipeline Processes In Brief:

Pre-processing:
	_pre0_split_vcf
  _pre1_filtering_PASS

Core-processing:
	_001_liftover
	_002_edit_vcf
	_003_concatenate_vcf
	_004_sort_and_compress

Post-processing:
	_pos1_count_lifted_variants

================================================================*/

/* Define the help message as a function to call when needed *//////////////////////////////
def helpMessage() {
	log.info"""
  ==========================================
  The gnomAD liftover pipeline
  - A genome coordinates convertion tool
  v${version}
  ==========================================

	Usage:

  nextflow run liftover.nf --vcf_dir <path to input 1> --genome_fasta <path to input 2> --chainfile <path to input 3> [--output_dir path to results] [--chunks INT] [--rehead true|false] [--filter_PASS true|false]

    --vcf_dir    <- Directory with all the vcf files to convert;
		    vcf must be in .vcf.gz format
    --genome_fasta  <- fasta file (.fa) for the liftover target genome reference;
        to improve runtime, the fasta file must have a .fai index, and it must reside in the same dir as the fasta; accepted extension is .fa
    --chainfile   <- UCSC chainfile to perform coordinate conversion;
        extension must be .chain; file must be uncompressed
        find them at http://crossmap.sourceforge.net/#chain-file
    --output_dir     <- directory where results, intermediate and log files will be stored;
				default: same level dir where --vcf_dir resides
		--chunks		<- each input vcf file will be split in INT pieces for parallelization;
				default: 1
		--rehead		<- clean output vcf header from unused contigs and append pipeline information;
				default: false	; enabling this severly increases runtime ## TODO: v>=0.0.7 remove this option from test, nf and other files
		--filter_PASS	<- keep only variants with PASS in the FILTER column of vcf;
				default: false  ; might overstimate unmapped variants by mixing noPASS with no liftover variants
	  --help           <- Show Pipeline Information
	  --version        <- Show Pipeline version
	""".stripIndent()
}

/*//////////////////////////////
  Define pipeline version
  If you bump the number, remember to bump it in the header description at the begining of this script too
*/
version = "0.0.6"

/*//////////////////////////////
  Define pipeline Name
  This will be used as a name to include in the results and intermediates directory names
*/
pipeline_name = "gnomADliftover"

/*
  Initiate default values for parameters
  to avoid "WARN: Access to undefined parameter" messages
*/
params.vcf_dir = false  //if no inputh path is provided, value is false to provoke the error during the parameter validation block
params.genome_fasta = false //if no inputh path is provided, value is false to provoke the error during the parameter validation block
params.chainfile = false //default is false to not trigger help message automatically at every run
params.jobs_per_vcf = 1 //default is 1, to not split each VCF input
params.rehead = false //default is to clean output vcf header from unused contigss, and append pipeline information
params.filter_PASS = false // default is false to process all of the orginal reported variants from the McArthur lab
params.help = false //default is false to not trigger help message automatically at every run
params.version = false //default is false to not trigger version message automatically at every run

/*//////////////////////////////
  If the user inputs the --help flag
  print the help message and exit pipeline
*/
if (params.help){
	helpMessage()
	exit 0
}

/*//////////////////////////////
  If the user inputs the --version flag
  print the pipeline version
*/
if (params.version){
	println "gnomeAD liftover Pipeline v${version}"
	exit 0
}

/*//////////////////////////////
  Define the Nextflow version under which this pipeline was developed or successfuly tested
  Updated by iaguilar at FEB 2019
*/
nextflow_required_version = '19.01'
/*
  Try Catch to verify compatible Nextflow version
  If user Nextflow version is lower than the required version pipeline will continue
  but a message is printed to tell the user maybe it's a good idea to update her/his Nextflow
*/
try {
	if( ! nextflow.version.matches(">= $nextflow_required_version") ){
		throw GroovyException('Your Nextflow version is older than Extend Align required version')
	}
} catch (all) {
	log.error "-----\n" +
			"  Pipeline requires Nextflow version: $nextflow_required_version \n" +
      "  But you are running version: $workflow.nextflow.version \n" +
			"  Pipeline will continue but some things may not work as intended\n" +
			"  You may want to run `nextflow self-update` to update Nextflow\n" +
			"============================================================"
}

/*//////////////////////////////
  INPUT PARAMETER VALIDATION BLOCK
  TODO (iaguilar) check the extension of input queries; see getExtension() at https://www.nextflow.io/docs/latest/script.html#check-file-attributes
*/

/* Check if bam_dir and genome_fasta were provided
    if they were not provided, they keep the 'false' value assigned in the parameter initiation block above
    and this test fails
*/
if ( !params.vcf_dir || !params.genome_fasta ) {
  log.error " Please provide both, the --vcf_dir AND the --genome_fasta \n\n" +
  " For more information, execute: nextflow run liftover.nf --help"
  exit 1
}

/*
Output directory definition
Default value to create directory is the parent dir of --vcf_dir
*/
params.output_dir = file(params.vcf_dir).getParent()

/*
  Results and Intermediate directory definition
  They are always relative to the base Output Directory
  and they always include the pipeline name in the variable (pipeline_name) defined by this Script

  This directories will be automatically created by the pipeline to store files during the run
*/
results_dir = "${params.output_dir}/${pipeline_name}-results/"
intermediates_dir = "${params.output_dir}/${pipeline_name}-intermediate/"

/*//////////////////////////////
  LOG RUN INFORMATION
*/
log.info"""
==========================================
The gnomAD liftover pipeline
- A genome coordinates convertion tool
v${version}
==========================================
"""
log.info "--Nextflow metadata--"
/* define function to store nextflow metadata summary info */
def nfsummary = [:]
/* log parameter values beign used into summary */
/* For the following runtime metadata origins, see https://www.nextflow.io/docs/latest/metadata.html */
nfsummary['Resumed run?'] = workflow.resume
nfsummary['Run Name']			= workflow.runName
nfsummary['Current user']		= workflow.userName
/* string transform the time and date of run start; remove : chars and replace spaces by underscores */
nfsummary['Start time']			= workflow.start.toString().replace(":", "").replace(" ", "_")
nfsummary['Script dir']		 = workflow.projectDir
nfsummary['Working dir']		 = workflow.workDir
nfsummary['Current dir']		= workflow.launchDir
nfsummary['Launch command'] = workflow.commandLine
log.info nfsummary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "\n\n--Pipeline Parameters--"
/* define function to store nextflow metadata summary info */
def pipelinesummary = [:]
/* log parameter values beign used into summary */
pipelinesummary['VCF dir']			= params.vcf_dir
pipelinesummary['Genome fasta']			= params.genome_fasta
pipelinesummary['ChainFile']			= params.chainfile
pipelinesummary['Chunks per VCF']			= params.chunks
pipelinesummary['Rehead VCF?']			= params.rehead
pipelinesummary['Filter PASS?']			= params.filter_PASS
pipelinesummary['Results Dir']		= results_dir
pipelinesummary['Intermediate Dir']		= intermediates_dir
/* print stored summary info */
log.info pipelinesummary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "==========================================\nPipeline Start"

/*//////////////////////////////
  PIPELINE START
*/

/*
	DEFINE PATHS TO MK MODULES
  -- every required file (mainly runmk.sh and mkfile, but also every accessory script)
  will be moved from this paths into the corresponding process work subdirectory during pipeline execution
  The use of ${workflow.projectDir} metadata guarantees that mkmodules
  will always be retrieved from a path relative to this NF script
*/

/* _pre0_split_vcf */
module_mk_pre0_split_vcf = "${workflow.projectDir}/mkmodules/mk-split-vcf-option3"

/* _pre1_filtering_PASS */
module_mk_pre1_filtering_PASS = "${workflow.projectDir}/mkmodules/mk-filtering-PASS"

/* _001_liftover */
module_mk_001_liftover = "${workflow.projectDir}/mkmodules/mk-liftover"

/* _002_edit_vcf TODO: posibly remove since the split stage edits the vcf file */
module_mk_002_edit_vcf = "${workflow.projectDir}/mkmodules/mk-edit-vcf"

/* _003_concatenate_vcf */
module_mk_003_concatenate_vcf = "${workflow.projectDir}/mkmodules/mk-concat-vcf"

/* _004_sort_and_compress */
module_mk_004_sort_and_compress = "${workflow.projectDir}/mkmodules/mk-sort-compress-vcf"

/* _pos1_count_lifted_variants */
module_mk_pos1_count_lifted_variants = "${workflow.projectDir}/mkmodules/mk-count-lifted-variants"

/*
	READ INPUTS
*/
/* Define function for finding files that share sample name */
/* in this case, the file name comes from the 1st, since tokenize array starts at 0, array index shoould be 0 */
def get_sample_prefix = { file -> file.name.toString().tokenize('.')[0] }

/* Load vcf files AND TABIX INDEX into channel */
Channel
  .fromPath("${params.vcf_dir}/*vcf*")
	.map{ file -> tuple(get_sample_prefix(file), file) }
	.groupTuple()
	// .view()
  .set{ vcf_inputs}

/* Load vcf files into channel , THIS SIMPLIFYES TUPPLING DURING POS1 STAGE*/
Channel
  .fromPath("${params.vcf_dir}/*vcf.bgz")
	// .view()
  .set{ also_vcf_inputs }

/* Load genome fasta file, and chainfile into channel */
Channel
	.fromPath( ["${params.genome_fasta}*" , "${params.chainfile}"], checkIfExists: true)
  .toList()
	.set{ liftover_references }

/* 	Process _pre0_split_vcf */
/* Read mkfile module files */
Channel
	.fromPath("${module_mk_pre0_split_vcf}/*")
	.toList()
	.set{ mkfiles_pre0 }

process _pre0_split_vcf {

	publishDir "${intermediates_dir}/_pre0_split_vcf/",mode:"symlink"

	input:
	set val( sample_name ), file( sample ) from vcf_inputs
	file mk_files from mkfiles_pre0

	output:
	file "*.chunk*.vcf" into results_pre0_split_vcf

	"""
	export NUMBER_OF_CHUNKS="${params.chunks}"
	bash runmk.sh
	"""

}

/* delay the next pipeline step by waiting to gather every previous file into a list, that is inmediatle unraveled into single elements again */
results_pre0_split_vcf
	.toList()
	.flatten()
	// .view()
	.set{ delayed_results_pre0_split_vcf }

/* 	Process _pre1_filtering_PASS */
/* Read mkfile module files */
Channel
	.fromPath("${module_mk_pre1_filtering_PASS}/*")
	.toList()
	.set{ mkfiles_pre1 }

process _pre1_filtering_PASS {

	publishDir "${intermediates_dir}/_pre1_filtering_PASS/",mode:"symlink"

	input:
  file vcf from delayed_results_pre0_split_vcf
	file mk_files from mkfiles_pre1

	output:

	file "*.vcf" into results_pre1_filtering_PASS
	"""
	export FILTER_FLAG=${params.filter_PASS}
	bash runmk.sh
	"""

}

/* delay the next pipeline step by waiting to gather every previous file into a list, that is inmediatle unraveled into single elements again */
results_pre1_filtering_PASS
	.toList()
	.flatten()
	// .view()
	.set{ delayed_results_pre1_filtering_PASS }

/* Process _001_liftover */
/* Read mkfile module files */
Channel
	.fromPath("${module_mk_001_liftover}/*")
	.toList()
	.set{ mkfiles_001 }

process _001_liftover {

	publishDir "${intermediates_dir}/_001_liftover/",mode:"symlink"

	input:
  file vcf from delayed_results_pre1_filtering_PASS
  file genome from liftover_references
	file mk_files from mkfiles_001

  output:
  file "*.liftover.vcf" into results_001_liftover_mapped
  file "*.unmap" into results_001_liftover_unmapped

	"""
  export CHAINFILE="\$(ls *.chain)"
  export REFERENCE_GENOME="\$(ls *.fa)"
  bash runmk.sh
	"""

}

/* Delay further processes until all of the samples have passed the previous one*/
results_001_liftover_mapped
	.toList()
	.flatten()
	// .view()
	.set{ delayed_results_001_liftover_mapped }

/* Process _002_edit_vcf */

/* Read mkfile module files */
Channel
	.fromPath("${module_mk_002_edit_vcf}/*")
	.toList()
	.set{ mkfiles_002 }

process _002_edit_vcf {

	publishDir "${intermediates_dir}/_002_edit_vcf/",mode:"symlink"

	input:
  file vcf from delayed_results_001_liftover_mapped
	file mk_files from mkfiles_002

  output:
  file "*.edited.vcf" into results_002_edit_vcf

	"""
  bash runmk.sh
	"""

}

/* Delay further processes until all of the samples have passed the previous one*/
results_002_edit_vcf
	.toList()
	.flatten()
	// .view()
	.set{ delayed_results_002_edit_vcf }

/* Gather every chunk into a single list object */
/* Separate in tuples by sample */
delayed_results_002_edit_vcf
// delayed_results_001_liftover_mapped
	.map{ file -> tuple(get_sample_prefix(file), file) }
	.groupTuple()
	// .view()
	.set{ multiplechunks_from_results_002_edit_vcf }

/* _003_concatenate_vcf */

/* Read mkfile module files */
Channel
	.fromPath("${module_mk_003_concatenate_vcf}/*")
	.toList()
	.set{ mkfiles_003 }

process _003_concatenate_vcf {

	publishDir "${intermediates_dir}/_003_concatenate_vcf/",mode:"symlink"

	input:
	set val( sample_name ), file( sample ) from multiplechunks_from_results_002_edit_vcf
	file mk_files from mkfiles_003

  output:
  file "*.vcf" into results_003_concatenate_vcf, also_results_003_concatenate_vcf

	"""
  bash runmk.sh
	"""
}

/* Delay further processes until all of the samples have passed the previous one*/
results_003_concatenate_vcf
	.toList()
	.flatten()
	// .view()
	.set{ delayed_results_003_concatenate_vcf }

/* _004_sort_and_compress */

/* Read mkfile module files */
Channel
	.fromPath("${module_mk_004_sort_and_compress}/*")
	.toList()
	.set{ mkfiles_004 }

/* Simplify command line string to avoid randomness from log names input in reports
	* Cut the command at the first ocurrence of the -with- option prefix
*/

command = workflow.commandLine - ~/-with-.+/

process _004_sort_and_compress {

	publishDir "${results_dir}/_004_sort_and_compress/",mode:"copy"

	input:
  file vcf from delayed_results_003_concatenate_vcf
	file mk_files from mkfiles_004

  output:
  file "*.vcf.bgz"

	"""
	export PIPELINE_VERSION="${version}"
	export PIPELINE_COMMAND="${command}"
  bash runmk.sh
	"""

}

/* Pos-processing block begins */
/* Gather and tupple original inputs, with concatenated outputs */
also_vcf_inputs
	.mix(also_results_003_concatenate_vcf)
	.map{ file -> tuple(get_sample_prefix(file), file) }
	.groupTuple()
	.set{ inputs_for_pos1 }

/* _pos1_count_lifted_variants */
/* Read mkfile module files */
Channel
	.fromPath("${module_mk_pos1_count_lifted_variants}/*")
	.toList()
	.set{ mkfiles_pos1 }

process _pos1_count_lifted_variants {

	publishDir "${results_dir}/_pos1_count_lifted_variants/",mode:"copy"

	input:
	set val( sample_name ), file( sample ) from inputs_for_pos1
	file mk_files from mkfiles_pos1

  output:
  file "*.tsv" into results_pos1_count_lifted_variants
  file "*.pdf"

	"""
  bash runmk.sh
	"""

}
