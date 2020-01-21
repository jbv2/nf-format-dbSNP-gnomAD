echo -e "======\n Testing NF execution \n======" \
&& rm -rf test/results/ \
&& nextflow run format_dbSNP_gnomAD.nf \
	--input_dir test/data/ \
	--output_dir test/results \
	-resume \
	-with-report test/results/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag test/results/`date +%Y%m%d_%H%M%S`.DAG.html \
&& echo -e "======\n Format dbSNP & gnomAD: Basic pipeline TEST SUCCESSFUL \n======"
