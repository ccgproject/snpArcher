# Setting Up snpArcher
## Environment Setup
First, we recommend installing Snakemake in a fresh [Mamba](https://github.com/mamba-org/mamba) environment:
```
mamba create -c conda-forge -c bioconda -n snparcher snakemake
mamba activate snparcher
```
Please see the [Snakemake docs](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for detailed installation instructions.

Next, clone the [snpArcher github repo](https://github.com/harvardinformatics/snpArcher) to your machine:
```
git clone https://github.com/harvardinformatics/snpArcher.git
cd snpArcher
```

## Creating a sample sheet
In order to determine what outputs to create, snpArcher requires sample sheet file. This comma separated file contains the required sample metadata about the your samples in order to run the workflow. At a minimum, the snpArcher pipeline requires that each sample have a unique sample name, a reference genome accession or a path to a fasta file, and a SRA accession, or path to two paired end fastq files. 

Below are all of the accepted fields for a sample sheet:
| Field | Description |
| ---- | -------------|
| BioSample | The name of the sample. |
| LibraryName | LibraryID for sample, **must be unique.** |
| Run | The SRR for the sample, if applicable. If not, must be some **unique** value. |
| refGenome | Reference genome accession, if applicable. *See note* |
| refPath | Path to local reference genome, if applicable. *See note* |
| BioProject | If applicable. Otherwise any value is acceptable. |
| fq1 | Optional. Path to read 1 for sample |
| fq2 | Optional. Path to read 2 for sample |
| SampleType | Optional. Triggers postproccesing module. Accepted values are 'include' or 'exclude' |

```{note}
refGenome is always required. refPath is optional, but when specified, a name for the assembly (in refGenome) must also be included. 
```

It is important to note that samples are proccessed together based on their `refGenome` metadata, so **all BioSamples that share a reference genome will ultimately end up in the same final vcf file.** If you are mapping multiple populations / species to a single reference genome, and want separate VCF files for each population / species, you will need to split your final vcf after the pipeline completes, or run multiiple indpendent sample sheets in different results directories. 

If your reads (and, optionally, your local reference genome) are stored in somewhere seperate of the workflow (e.g.: a scratch disk) then you can specify the path to your reads using the `fq1` and `fq2` fields, and the location of your reference genome fasta (*note: must be uncompressed*) in the `refPath` field. 

### Using data from NCBI SRA
If you'd like to reanalyze an existing NCBI SRA BioProject, please follow these instructions to quickly create a sample sheet.

1. Go to the BioProject overview web page on the SRA.
2. In the subheading `Project Data` there is a table with the columns `Resource Name` and `Number of Links`. Click the link in the `Number of Links` column in the `SRA Experiments` row. You will be redirected to a search results page.
3. Near the top of the search results page, click the link `Send results to Run Selector`
4. On the Run Selector page, you can select/deselect samples you'd like to include/exclude in your sample sheet by using the checkboxes.
5. Once you are done selecting samples, click the `Metadata` button in the `Download` column in the table near the middle of the page.
6. This will download a a comma separated file called `SraRunTable.txt`.
7. Open the file in the editor of your choice, and add a column named `refGenome`. In this column, enter the reference genome accession you want to use for every row in the sheet.
8. Save the sample sheet, it is now ready to use.

### Using local data
A python script `workflow/write_samples.py` is included to help write the sample sheet for you. In order to use this script, you must have organized all of your fastq files in to one directory. The script requies you provide a file with one sample per name that maps uniquely to a pair of fastq files in the afformentioned directory. The script also requires either a reference genome accession or path to reference fasta. 

Usage details: 

|Argument| Description|
| ------ | ---------- |
| `-s / --sample_list` | Path to a sample list. One sample per line |
| `-f / --fastq_dir` | Path to directory containing ALL fastq files. It is assumed that each fastq file will contain the sample name uniquely. |
| `-r / --ref` | Path to reference fasta. Mutually exclusive with -a|
| `-a / --acc` | NCBI accession of reference. Mutually exclusive with -r|

## Configuring snpArcher

Workflow variables such as output file prefix, tool settings, and other options are set in `config/config.yaml`. Resource settings such as threads and memory are controlled per tool in the `config/resources.yaml`.

### Core configuration
The following options in `config/config.yaml` must be set before running snpArcher:

| Option | Description | Type |
| ---- | -------------| ------ |
| `samples` | Path to CSV sample sheet.| `str` |
| `resource_config` | Path to resources YAML file | `str` |
| `final_prefix` | Prefix to name final output files with (e.g. VCF) | `str` |
| `intervals` |  Use SplitByN interval approach for GATK variant calling | `bool` |
| `sentieon` | Use Sentieon tools instead of GATK for variant calling | `bool` |
| `sentieon_lic` | If using Sentieon tools, provide license here | `str` |
| `remote_reads` | Use remote storage provider (Google) for reads | `bool` |
| `remote_reads_prefx` | The bucket where remote reads are stored | `str` |
| `bigtmp` | Set a directory for TMP. Default is $TMPDIR env var | `str` |
| `cov_filter` | Use coverage thresholds for filtering callable sites | `bool`|
| `generate_trackhub` | Generate population genomics stats trackhub | `bool`|
| `trackhub_email` | Trackhubs require an email address | `str` |


### Other options
The following options can be adjusted based on your needs and your dataset.

#### Variant Calling Options
| Option | Description | Type |
| ---- | -------------| ------ |
|`minNmer`| The minimum span of Ns to split reference genome at for interval generation | `int`|
|`num_gvcf_intervals` | The maximum number of GVCF intervals to create. Actual number of intervals may be less if reference genome is highly contiguous. | `int`|
|`db_scatter_factor` | Used to calculate number of DB intervals to create. `num_db_intervals = (scatter_factor * num_samples * num_gvcf_intervals)`. Recommend <1 | `float`|
| `minP` | Controls `--min-pruning` in GATK HaplotypeCaller. Recommend 1 for low coverage (<10x), 2 for high coverage (>10x) | `int` |
| `minD` | Controls `--min-dangling-branch-length` in GATK HaplotypeCaller. Recommend 1 for low coverage (<10x), 4 for high coverage (>10x) | `int` |

#### Callable Sites Options
| Option | Description | Type |
| ---- | -------------| ------ |
|`mappability_min`| Genomic regions with mappability score less than this will be removed from callable sites. | `int`|
|`mappability_k`| Kmer size to compute mappability. | `int`|
|`mappability_merge`| Merge passing mappability regions separated by this or fewer basepairs into a signle region | `int`|
|`cov_merge`| Merge passing coverage regions separated by this or fewer basepairs into a signle region | `int`|

#### Coverage Filtering Options
If `cov_filter` in the core options is set to `True`, then the following options can be adjusted to the user's needs. Coverage filtering can be handled 3 ways:

1. Hard upper and lower thresholds: regions with a mean coverage that falls within these thresholds are considered callable.

| Option | Description | Type |
| ---- | -------------| ------ |
|`cov_threshold_lower`| Lower coverage threshold| `int`|
|`cov_threshold_upper`| Upper coverage threshold| `int`|

2. Standard deviations: regions with a mean coverage that is within N standard deviations (assumes Poisson distribution) are considered callable.

| Option | Description | Type |
| ---- | -------------| ------ |
|`cov_threshold_stdev`| Number of standard deviations is considered callable | `int`|

3. Absolute scaling: Thresholds set by factor N. Lower bowund is (global mean coverage / N), upper bound (global mean coverage * N). A region is callable if its mean coverage is within these bounds.

| Option | Description | Type |
| ---- | -------------| ------ |
|`cov_threshold_rel`| Scaling factor for coverage threshold| `int`|

```{note}
In order to use one of the above coverage filtering approaches, you must set the options of the desired approach, and leave the others blank.
```

#### QC Module Options
For more details about this module, please see [here](./modules.md#quality-control).

| Option | Description | Type |
| ---- | -------------| ------ |
|`nClusters`| Number of clusters for PCA| `int`|
|`GoogleAPIKey`| Google Maps API key (optional).| `str`|
|`min_depth`| Samples with average depth below this will be excluded for QC analysis| `int`|

#### Postprocessing Module Options
For more details about this module, please see [here](./modules.md#postprocessing).

| Option | Description | Type |
| ---- | -------------| ------ |
|`contig_size`| SNPs on contigs this size or smaller will be excluded from 'clean' VCF | `int`|
|`maf`| SNPs with MAF below this will be excluded from clean VCF| `float`|
|`missingness`| SNPs with missingness below this will be excluded from clean VCF| `float`|
|`scaffolds_to_exclude` | Comma separated, no spaces list of scaffolds/contigs to exclude from clean VCF|










