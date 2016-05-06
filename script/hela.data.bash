# download fastq
module load fabbus/aria2/1.18.8

pin=/share/ScratchGeneral/phuluu/aberrant.transcript/hela/fastq/ERP001458.txt

awk -F'\t' 'NR>1{print $12}' $pin| awk -F';' '{print "ftp://"$1"\n""ftp://"$2}'\
|xargs -I url -n 1 aria2c -c -x16 -j18 -s16 --file-allocation=none url

# mapping with tophat
module load gi/ngsane/0.5.2
ls /share/ClusterShare/software/contrib/gi/ngsane/0.5.2/sampleConfigs/

# copy config file-allocation
cd /share/ScratchGeneral/phuluu/aberrant.transcript/hela/config
cp /share/ClusterShare/software/contrib/gi/ngsane/0.5.2/sampleConfigs/fastqc_config.txt .

# fastq
/share/ScratchGeneral/phuluu/aberrant.transcript/hela$ trigger.sh config/01_fastqc_config.txt armed

# tophat
# The RNA-seq data were mapped using the splice-aware alignment algorithm TopHat version 1.1.4 (Trapnell et al., 2009) 
# based on the following parameters: tophat -num-threads 8 -mate-inner-dist 200 -solexa-quals -min-isoform-fraction 0 
# -coverage-search -segment-mismatches 1. More than 80% of all RNA-seq reads mapped uniquely to the human genome (Table S1), 
# and 83% of these mapped as part of perfect read pairs.
cd /share/ScratchGeneral/phuluu/aberrant.transcript/hela/
cp /share/ClusterShare/software/contrib/gi/ngsane/0.5.2/sampleConfigs/tophat_config.txt config/02_tophat_config.txt
trigger.sh config/02_tophat_config.txt
trigger.sh config/02_tophat_config.txt armed
# cufflinks
# In order to predict exons from our RNA-seq data, we ran Cufflinks (version 0.9.3, -min-isoform-fraction 0 
# to allow detection of weakly included exons; Trapnell et al., 2010) on the collapsed reads from all control and 
# HNRNPC knockdown samples and then extracted the exons of all predicted transcripts. 
module load gi/ngsane/0.5.2
cd /share/ScratchGeneral/phuluu/aberrant.transcript/hela/
cp /share/ClusterShare/software/contrib/gi/ngsane/0.5.2/sampleConfigs/cufflinks_config.txt 03_cufflinks_config.txt
trigger.sh config/03_cufflinks_config.txt
trigger.sh config/03_cufflinks_config.txt armed
# In order to minimize noise due to erroneous
# or highly overlapping annotations, we kept only exons that (a) were predicted as part of multi-exon transcripts, 
# (b) were supported by at least one junction-spanning read, and (c) had a size of at least 25 bp and no more than 10 kb. 
# Finally, overlapping exons that started/ended less than 25 bp from each other were merged into one exon using the outer exon boundaries.
# Applying these filters, Cufflinks predicted a total of 178,029 exons (reported as ‘Total’ in Table S2), 
# including 16,143 exons that did not overlap with any exon in the Ensembl database and thus represented good candidates 
# for cryptic exons. We used Ensembl gene annotations to assign the exons to gene models. 
# Exons that directly overlapped with an Ensembl gene or that were part of a predicted Cufflinks gene model that overlapped 
# with only one Ensembl gene were assigned to that gene. We discarded exons that overlapped with more than one Ensembl gene. 
# Applying this procedure, Cufflinks-predicted exons could be associated with 14,091 Ensembl genes. 
# For the alternative splicing analyses using DEXSeq, we further restricted the set to exons that did not overlap with 
# any other annotated exon (“Non-overlapping” in Table S2).

# To identify Alu exons, we searched for Cufflinks-predicted exons that contained at least one splice site within an 
# antisense Alu element (taken from RepBase; see below). The Alu-derived splice site had to be supported by at least one 
# junction-spanning read in our collapsed RNA-seq data. Following this definition, Cufflinks exon predicted a total 2,085 Alu exons 
# (Table S2). 1,376 of these were predicted to introduce a frameshift, and 472, 610, and 797 harbored a stop codon in one, 
# two and all three frames, respectively. Combining this evidence, 1,655 (79%) of the Alu exons were predicted to disrupt the 
# respective transcript upon inclusion. 1,903 of the Alu exons did not overlap with any other exon prediction (nonoverlapping) 
# and were thus used for all following analyses, including 1,318 Alu exons that did not overlap with any Ensembl annotation. 
# We notice that some Alu exons are expressed at negligible levels in the control sample; however given that they remain unannotated and 
# they are largely undetectable in our RNA-seq data, they are unlikely to play an important role under normal conditions. 
# We further identified a control set of 81 established Alu exons that show substantial inclusion already in control HeLa cells and 
# that do no longer underlie hnRNP C regulation (Alu exons harboring a total of at least 50 reads in our RNA-seq samples and showing 
# a fold change < 1.5 [KD/ctrl]).
#

# 
module load gi/bedtools/2.22.0
module load gi/samtools/1.2
module load gi/picard-tools/1.138
module load phuluu/R/3.1.2
module load phuluu/python/2.7.8

repeat=/share/ScratchGeneral/phuluu/repeat/data/ucsc/rmsk_short.txt
transcripts=/share/ScratchGeneral/phuluu/aberrant.transcript/hela/HNRNPC.KD1.R1/cufflinks/ERR127302/transcripts.gtf
path=/share/ScratchGeneral/phuluu/aberrant.transcript/Repbase

grep "Alu" $repeat > $path/alu.bed 
bedtools intersect -a $path/alu.bed -b $transcripts -wa -wb > /share/ScratchGeneral/phuluu/aberrant.transcript/hela/HNRNPC.KD1.R1/cufflinks/ERR127302/transcripts.overlap.alu.gtf
