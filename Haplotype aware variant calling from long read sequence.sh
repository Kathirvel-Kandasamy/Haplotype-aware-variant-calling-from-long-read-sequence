#!/bin/sh
reference=$HOME/LongRead/Reference/hg19.fa
minimap2 -t 64 -d $HOME/LongRead/Reference/hg19_Index.mmi $reference
Indexed_reference=$HOME/LongRead/Reference/hg19_Index.mmi
##Quality Check
cd $HOME/LongRead/fastq
for i in $(ls *.fastq.gz | uniq); do fastqc ${i} > ${i%}_quality;done
##Find matching adapter by overlapping reads and trim them
for i in $(ls *.fastq.gz | uniq); do porechop -i ${i} -o ${i}_trimmed.fastq.gz --threads 64;done
##Mapping with Reference hg19 by minimap2
for i in $(ls *_trimmed.fastq.gz | uniq); do minimap2 -t 64 -ax map-ont -a $Indexed_reference ${i} > ${i%}_minimap2.bam;done
for bam in $(ls *_minimap2.bam); do if test -f $bam; then
  echo "Mapping is done."
fi;done
for bam in $(ls *_minimap2.bam); do if ! test -f $bam; then
  echo "Problem with Mapping, something isn't correct"
fi;done
##Adding Read group information for each bam files with sample and platform details
for i in $(ls *._minimap2.bam | uniq); do java  -jar  $HOME/LongRead/Softwares/picard/picard.jar AddOrReplaceReadGroups I=${i} O=${i%}_picard.bam RGID=XXXX RGLB=XXXX RGPL=XXXX RGPU=XXXX RGSM=${i};done
for bam in $(ls *_picard.bam); do if test -f $bam; then
  echo "Adding Read group is done."
fi;done
for bam in $(ls *_picard.bam); do if ! test -f $bam; then
  echo "Problem with Adding Read group, something isn't correct"
fi;done
##Sorting the bam file
for i in $(ls *_picard.bam | uniq); do samtools sort ${i} > ${i%}_sorted.bam;done
##Indexing the bam file
for i in $(ls *_sorted.bam | uniq); do samtools index ${i} > ${i%}.bai;done
for i in $(ls *_sorted.bam | uniq); do samtools flagstat ${i} > ${i%}_mapping_stats;done
##Calling Variants by gatk
for i in $(ls *_sorted.bam | uniq); do $HOME/LongRead/Softwares/gatk/./gatk --java-options "-Xmx96g" HaplotypeCaller -R $reference -I ${i} -O ${i%}_gatk.vcf;done
for vcf in $(ls *_gatk.vcf); do if test -f $vcf; then
  echo "variant calling is done."
fi;done
for vcf in $(ls *_gatk.vcf); do if ! test -f $vcf; then
  echo "Problem with variant calling, something isn't correct"
fi;done

##snpsift for rsID
for i in $(ls *_gatk.vcf | uniq); do java "-Xmx96g" -jar $HOME/LongRead/Softwares/snpEff/SnpSift.jar annotate -id $HOME/LongRead/Reference/Homo_sapiens_assembly19.dbsnp138.vcf ${i} > ${i%}_snpsift.vcf;done
for vcf in $(ls *_snpsift.vcf); do if test -f $vcf; then
  echo "variant annotation for rsID is done."
fi;done
for vcf in $(ls *_snpsift.vcf); do if ! test -f $vcf; then
  echo "Problem with variant annotation for rsID, something isn't correct"
fi;done
##snpeff for predicting the impact of varints
for i in $(ls *_snpsift.vcf | uniq); do java "-Xmx96g" -jar $HOME/LongRead/Softwares/snpEff/snpEff.jar hg19 ${i} > ${i%}_snpeff.vcf;done
for vcf in $(ls *_snpeff.vcf); do if test -f $vcf; then
  echo "Prediction of Impact of variants is done."
fi;done
for vcf in $(ls *_snpeff.vcf); do if ! test -f $vcf; then
  echo "Problem with Prediction of Impact of variants, something isn't correct"
fi;done
##Haplotype aware vcf creation
###Phasing
bam=(*_sorted.bam)
vcf=(*_snpeff.vcf)
for ((i=0; i<${#bam[@]}; i++)); do whatshap phase -o ${i%}_haplotyped_phased.vcf --reference=$reference "${vcf[i]}" "${bam[i]}" ;done
for vcf in $(ls *_haplotyped_phased.vcf); do if test -f $vcf; then
  echo "Phasing is done."
fi;done
for vcf in $(ls *_haplotyped_phased.vcf); do if ! test -f $vcf; then
  echo "Problem with Phasing, something isn't correct"
fi;done
##Creating Haplotagged BAM
for i in $(ls *_haplotyped_phased.vcf | uniq); do bgzip ${i};done
for i in $(ls *_haplotyped_phased.vcf.gz | uniq); do tabix ${i};done
for i in $(ls *_haplotyped_phased.vcf.gz | uniq); do whatshap stats ${i} > ${i%}_stats.txt;done
for i in $(ls *_haplotyped_phased.vcf.gz | uniq); do whatshap stats --gtf=${i%}.gtf ${i};done
bam=(*_sorted.bam)
vcf=(*_phased.vcf.gz)
for ((i=0; i<${#bam[@]}; i++)); do whatshap haplotag -o ${i%}_haplotagged.bam --reference $reference "${vcf[i]}" "${bam[i]}";done
for vcf in $(ls *_haplotagged.bam); do if test -f $vcf; then
  echo "haplotagged BAM creation is done."
fi;done
for vcf in $(ls *_haplotagged.bam); do if ! test -f $vcf; then
  echo "Problem with haplotagged BAM creation, something isn't correct"
fi;done
for i in $(ls *_haplotagged.bam | uniq); do samtools index ${i} > ${i%}.bai;done
mv *_sorted.bam *_sorted.bam.bai $HOME/LongRead/Final_BAM/
mv *_gatk.vcf gatk_vcf/
mv *_snpsift.vcf *_snpeff.vcf $HOME/LongRead/snpeff/
mv *_haplotyped_phased.vcf *_haplotyped_phased.vcf.gz *_haplotyped_phased.vcf.gz.idx *_stats.txt *.gtf *haplotagged.bam *haplotagged.bam.bai $HOME/LongRead/whatshap/
mv *_minimap2.bam *_picard.bam *_mapping_stats $HOME/LongRead/Others/





