---
layout: post
title: Transcriptome Compression - P.generosa Transcriptome Assemblies Using CD-Hit-est on Mox
date: '2019-07-29 13:58'
tags:
  - Panopea generosa
  - geoduck
  - transcriptome
  - trinity
  - CD-hit
  - mox
categories:
  - Miscellaneous
---
In continued attempts to get a grasp on the geoduck transcriptome size, I decided to "compress" our various assemblies by clustering similar transcripts in each assembly in to a single "representative" transcript, using [CD-Hit-est](http://weizhongli-lab.org/cd-hit/). Settings use to run it were taken from the [Trinity FAQ regarding "too many transcripts"](https://github.com/trinityrnaseq/trinityrnaseq/wiki/There-are-too-many-transcripts!-What-do-I-do%3F).

A bash script was used to `rsync` files to Mox and then execute the SBATCH script.

Bash script (GitHub):

- [20190729_rsync_pgen_trinity_assemblies.sh](https://github.com/RobertsLab/sams-notebook/blob/master/bash_scripts/20190729_rsync_pgen_trinity_assemblies.sh)

```shell
#!/usr/bin/bash

# Script to retrieve geoduck Trinity assemblies
# Assemblies will be used in SBATCH script called at end of this script.
# Script needs to be run within same directory as SBATCH script.

# Exit if any command fails
set -e

# Set rsync remote path
gannet="gannet:/volume2/web/Atumefaciens"
owl="owl:/volume1/web/Athaliana"

# Create array of directories for storing Trinity assemblies
assembly_dirs_array=(
/gscratch/srlab/sam/data/P_generosa/transcriptomes/20180827_assembly
/gscratch/srlab/sam/data/P_generosa/transcriptomes/ctenidia
/gscratch/srlab/sam/data/P_generosa/transcriptomes/gonad
/gscratch/srlab/sam/data/P_generosa/transcriptomes/heart
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI115
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI116
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI123
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI124
/gscratch/srlab/sam/data/P_generosa/transcriptomes/larvae/EPI99)

# Array of Trinity assemblies remote paths for rysnc-ing
assemblies_array=(
20180827_trinity_geoduck_RNAseq/Trinity.fasta
20190409_trinity_pgen_ctenidia_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_gonad_RNAseq/trinity_out_dir/Trinity.fasta
20190215_trinity_geoduck_heart_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_EPI115_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_EPI116_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_EPI123_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_EPI124_RNAseq/trinity_out_dir/Trinity.fasta
20190409_trinity_pgen_EPI99_RNAseq/trinity_out_dir/Trinity.fasta)

# Retrieve FastA files via rsync
for index in "${!assemblies_array[@]}"
do
  # Remove everything after first slash
  assembly=$(echo "${assemblies_array[index]%%/*}")
  echo "Preparing to download ${assembly}..."
  if [ "${assembly}" = "20180827_trinity_geoduck_RNAseq" ]; then
    echo "Now syncing ${assembly} to ${assembly_dirs_array[index]}"
    rsync \
    --archive \
    --progress \
    "${owl}/${assemblies_array[index]}" \
    "${assembly_dirs_array[index]}"
  else
  echo "Now syncing ${assembly} to ${assembly_dirs_array[index]}"
  rsync \
  --archive \
  --progress \
  "${gannet}/${assemblies_array[index]}" \
  "${assembly_dirs_array[index]}"
  fi
done

# Start SBATCH script to run CD-Hit on all transcriptome assemblies
sbatch 20190729_cdhit-est_pgen_transcriptomes.sh
```


SBATCH script (GitHub):

- [20190729_cdhit-est_pgen_transcriptomes.sh](https://github.com/RobertsLab/sams-notebook/blob/master/sbatch_scripts/20190729_cdhit-est_pgen_transcriptomes.sh)

```shell
#!/bin/bash
## Job Name
#SBATCH --job-name=cdhit_pgen
## Allocation Definition
#SBATCH --account=srlab
#SBATCH --partition=srlab
## Resources
## Nodes
#SBATCH --nodes=1
## Walltime (days-hours:minutes:seconds format)
#SBATCH --time=5-00:00:00
## Memory per node
#SBATCH --mem=120G
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=samwhite@uw.edu
## Specify the working directory for this job
#SBATCH --workdir=/gscratch/scrubbed/samwhite/outputs/20190729_cdhit-est_pgen_transcriptomes

# This script is called by 20190729_cdhit_pgen_trinity_assemblies.sh.
# That script uses rsync to transfer files to Mox via the login node.
# This is required because Mox execute nodes don't have internet access.

# Exit script if any command fails
set -e

# Load Python Mox module for Python module availability

module load intel-python3_2017

# Document programs in PATH (primarily for program version ID)

date >> system_path.log
echo "" >> system_path.log
echo "System PATH for $SLURM_JOB_ID" >> system_path.log
echo "" >> system_path.log
printf "%0.s-" {1..10} >> system_path.log
echo "${PATH}" | tr : \\n >> system_path.log

# Set CPU threads
threads=27

# Program paths
cd_hit_est="/gscratch/srlab/programs/cd-hit-v4.8.1-2019-0228/cd-hit-est"

# Create assembly paths array
assembly_dirs_array=(
/gscratch/srlab/sam/data/P_generosa/transcriptomes/20180827_assembly
/gscratch/srlab/sam/data/P_generosa/transcriptomes/ctenidia
/gscratch/srlab/sam/data/P_generosa/transcriptomes/gonad
/gscratch/srlab/sam/data/P_generosa/transcriptomes/heart
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI115
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI116
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI123
/gscratch/srlab/sam/data/P_generosa/transcriptomes/juvenile/EPI124
/gscratch/srlab/sam/data/P_generosa/transcriptomes/larvae/EPI99)

# Run cd-hit-est on each assembly
for index in "${!assembly_dirs_array[@]}"
do
  # Store individual sample name by removing
  # everything up to and including the last slash in path
  sample_name=$(echo "${assembly_dirs_array[index]##*/}")
  # Run cd-hit-est
  "${cd_hit_est}" \
  -o "${sample_name}".cdhit \
  -c 0.98 \
  -i "${assembly_dirs_array[index]}"/Trinity.fasta \
  -p 1 \
  -d 0 \
  -b 3 \
  -T "${threads}" \
  -M 0
done
```

---

#### RESULTS

Output folder:

- [20190729_cdhit-est_pgen_transcriptomes/](https://gannet.fish.washington.edu/Atumefaciens/20190729_cdhit-est_pgen_transcriptomes/)