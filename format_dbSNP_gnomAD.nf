#!/usr/bin/env nextflow

/*================================================================
The MORETT LAB presents...

  A Pipeline for making usable dbSNP vcf and coverage of gnomAD.

==================================================================
Version: 0.0.1
Project repository:
==================================================================
Authors:

- Bioinformatics Design
 Judith Ballesteros Villascán (judith.vballesteros@gmail.com)

- Bioinformatics Development
Judith Ballesteros Villascán (judith.vballesteros@gmail.com)

- Nextflow Port
 Judith Ballesteros Villascán (judith.vballesteros@gmail.com)

=============================
Pipeline Processes In Brief:

Core-processing:
  _001_tsv2bed
  _002_change_chr_nomenclature


================================================================*/

/* Define the help message as a function to call when needed *//////////////////////////////
def helpMessage() {
	log.info"""
  ==========================================
  The format dbSNP & gnomAD Pipeline
  v${version}
  ==========================================

	Usage:

  nextflow run format_dbSNP_gnomAD.nf --input_dir <path to input_dir> [--output_dir path to results ]

	  --input_dir   <- directory with:
				dbSNP vcf accepted extension is .gz;
				vcf file must have a TABIX index with .tbi extension, located in the same directory as the vcf file
        gnomAD tsv coverage, accepted extension is .tsv.gz;
	  --output_dir     <- directory where results, intermediate and log files will bestored;
				default: same dir where --query_fasta resides
	  -resume	   <- Use cached results if the executed project has been run before;
				default: not activated
				This native NF option checks if anything has changed from a previous pipeline execution.
				Then, it resumes the run from the last successful stage.
				i.e. If for some reason your previous run got interrupted,
				running the -resume option will take it from the last successful pipeline stage
				instead of starting over
				Read more here: https://www.nextflow.io/docs/latest/getstarted.html#getstart-resume
	  --help           <- Shows Pipeline Information
	  --version        <- Show Pipeline version
	""".stripIndent()
}

/*//////////////////////////////
  Define pipeline version
  If you bump the number, remember to bump it in the header description at the begining of this script too
*/
version = "0.0.1"

/*//////////////////////////////
  Define pipeline Name
  This will be used as a name to include in the results and intermediates directory names
*/
pipeline_name = "format_dbSNP_gnomAD"

/*
  Initiate default values for parameters
  to avoid "WARN: Access to undefined parameter" messages
*/
params.vcffile = false  //if no inputh path is provided, value is false to provoke the error during the parameter validation block
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
	println "VEP Annotator v${version}"
	exit 0
}

/*//////////////////////////////
  Define the Nextflow version under which this pipeline was developed or successfuly tested
  Updated by iaguilar at FEB 2019
*/
nextflow_required_version = '18.10.1'
/*
  Try Catch to verify compatible Nextflow version
  If user Nextflow version is lower than the required version pipeline will continue
  but a message is printed to tell the user maybe it's a good idea to update her/his Nextflow
*/
try {
	if( ! nextflow.version.matches(">= $nextflow_required_version") ){
		throw GroovyException('Your Nextflow version is older than Pipeline required version')
	}
} catch (all) {
	log.error "-----\n" +
			"  This pipeline requires Nextflow version: $nextflow_required_version \n" +
      "  But you are running version: $workflow.nextflow.version \n" +
			"  The pipeline will continue but some things may not work as intended\n" +
			"  You may want to run `nextflow self-update` to update Nextflow\n" +
			"============================================================"
}

/*//////////////////////////////

*/

/* Check if vcffile provided
    if they were not provided, they keep the 'false' value assigned in the parameter initiation block above
    and this test fails
*/

/*
  Results and Intermediate directory definition
  They are always relative to the base Output Directory
  and they always include the pipeline name in the variable (pipeline_name) defined by this Script

  This directories will be automatically created by the pipeline to store files during the run
*/
results_dir = "${params.output_dir}/${pipeline_name}-results/"
//intermediates_dir = "${params.output_dir}/${pipeline_name}-intermediate/"

/*
Useful functions definition
*/
/* define a function for extracting the file name from a full path */
/* The full path will be the one defined by the user to indicate where the reference file is located */
def get_baseName(f) {
	/* find where is the last appearance of "/", then extract the string +1 after this last appearance */
  	f.substring(f.lastIndexOf('/') + 1);
}


/*//////////////////////////////
  LOG RUN INFORMATION
*/
log.info"""
==========================================
The format dbSNP & gnomAD Pipeline
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
// pipelinesummary['vars per chunk']			= params.variants_per_chunk
pipelinesummary['Results Dir']		= results_dir
/* print stored summary info */
log.info pipelinesummary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "==========================================\nPipeline Start"

/*//////////////////////////////
  PIPELINE START
*/

/*
	READ INPUTS
*/

/* Load tsv file into channel */
Channel
  .fromPath( "${params.input_dir}/*.tsv.bgz" )
	.toList()
  .set{ tsv_input }

/* _001_tsv2bed */
/* Read mkfile module files */
Channel
	.fromPath("${workflow.projectDir}/mkmodules/mk-tsv2bed-gnomAD-coverage/*")
	.toList()
	.set{ mkfiles_001 }

process _001_tsv2bed {

	publishDir "${results_dir}/_001_tsv2bed/",mode:"copy"

	input:
	file tsv from tsv_input
	file mk_files from mkfiles_001

	output:
	file "*.bed.gz*" into results_001_tsv2bed

	"""
	bash runmk.sh
	"""

}

/* 	Process _002_change_chr_nomenclature */

/* Load vcf file and index into channel */
Channel
  .fromPath( "${params.input_dir}/*.gz*" )
	.toList()
  .set{ vcf_input }

/* Read mkfile module files */
Channel
	.fromPath("${workflow.projectDir}/mkmodules/mk-change-chr-dbSNP/*")
	.toList()
	.set{ mkfiles_002 }

process _002_change_chr_nomenclature {

	publishDir "${results_dir}/_002_change_chr_nomenclature/",mode:"copy"

	input:
	file vcf from vcf_input
	file mk_files from mkfiles_002

	output:
	file "*.vcf.gz*" into results_002_change_chr_nomenclature

	"""
  export NAMES_CHR="${params.names_chr}"
	bash runmk.sh
	"""

}
