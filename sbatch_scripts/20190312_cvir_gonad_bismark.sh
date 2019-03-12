#!/bin/bash
## Job Name
#SBATCH --job-name=bismark
## Allocation Definition
#SBATCH --account=coenv
#SBATCH --partition=coenv
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=10-00:00:00
## Memory per node
#SBATCH --mem=120G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --workdir=/gscratch/scrubbed/samwhite/outputs/2019312_cvir_gonad_bismark

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Document programs in PATH (primarily for program version ID)

date >> system_path.log
echo "" >> system_path.log
echo "System PATH for $SLURM_JOB_ID" >> system_path.log
echo "" >> system_path.log
printf "%0.s-" {1..10} >> system_path.log
echo ${PATH} | tr : \\n >> system_path.log


# Directories and programs
wd=$(pwd)
bismark_dir="/gscratch/srlab/programs/Bismark-0.19.0"
bowtie2_dir="/gscratch/srlab/programs/bowtie2-2.3.4.1-linux-x86_64/"
samtools="/gscratch/srlab/programs/samtools-1.9/samtools"
reads_dir="/gscratch/srlab/sam/data/C_virginica/bsseq"

## genomes

genome="/gscratch/srlab/sam/data/C_virginica/genomes/"

## Concatenated FastQ Files
R1="${wd}/cvir_bsseq_all_pe_R1.fastq.gz"
R2="${wd}/cvir_bsseq_all_pe_R2.fastq.gz"

## FastQ files lists
R1_list="${wd}/cvir_bsseq_pe_all_R1.list"
R2_list="${wd}/cvir_bsseq_pe_all_R2.list"

## Save FastQ files to arrays
R1_array=(${reads_dir}/*_R1_*.fq.gz)
R2_array=(${reads_dir}/*_R2_*.fq.gz)

# Check for existence of previous concatenation
# If they exist, delete them

for file in ${R1} ${R1_list} ${R2} ${R2_list}
do
  if [ -e ${file} ]; then
    rm ${file}
  fi
done

# Concatenate R1 reads and generate lists of FastQs
for fastq in ${reads_dir}*R1*.gz
do
  echo ${fastq} >> ${R1_list}
  cat ${fastq} >> ${R1}
done

# Concatenate R2 reads and generate lists of FastQs
for fastq in ${reads_dir}*R2*.gz
do
  echo ${fastq} >> ${R2_list}
  cat ${fastq} >> ${R2}
done
