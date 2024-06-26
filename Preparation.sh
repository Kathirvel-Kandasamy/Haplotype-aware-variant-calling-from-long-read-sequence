#!/bin/sh
HOME="/home/Kathir"
mkdir $HOME/LongRead
cd $HOME/LongRead
mkdir fastq Reference Mapping Final_BAM gatk_vcf snpeff whatshap Softwares Others
##Downloading Reference and Indexing
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/chromFa.tar.gz
cat chr1.fa chr2.fa chr3.fa chr4.fa chr5.fa chr6.fa chr7.fa chr8.fa chr9.fa chr10.fa chr11.fa chr12.fa chr13.fa chr14.fa chr15.fa chr16.fa chr17.fa chr18.fa chr19.fa chr20.fa chr21.fa chr22.fa chrX.fa chrY.fa chrM.fa > $HOME/LongRead/Reference/hg19.fa
if test -f $HOME/LongRead/Reference/hg19.fa; then
  echo "Downloading hg19 reference genome is done."
fi 
if ! test -f $HOME/LongRead/Reference/hg19.fa; then
  echo "Problem in hg19 reference genome downloading, something isn't correct"
fi
mv * $HOME/LongRead/Others/
##Install fastqc
cd $HOME/LongRead/Softwares/
sudo apt-get install fastqc
##Install minimap2
sudo apt-get install minimap2
##picard
git clone https://github.com/broadinstitute/picard.git
cd picard/
./gradlew shadowJar
cp build/libs/picard.jar ../picard/
##samtools and bcf tools installation
cd $HOME/LongRead/Softwares/
wget https://github.com/samtools/samtools/releases/download/1.20/samtools-1.20.tar.bz2
tar -xvf samtools-1.20.tar.bz2
cd samtools-1.20
./configure
make
make install
##Install gatk
cd $HOME/LongRead/Softwares/
wget https://github.com/broadinstitute/gatk/archive/refs/tags/4.5.0.0.tar.gz
tar -xvf 4.5.0.0.tar.gz
mv gatk-4.5.0.0/ gatk
##snpeff and snpsift installation
wget https://snpeff.blob.core.windows.net/versions/snpEff_latest_core.zip
unzip snpEff_latest_core.zip
#rsID annotation and prediction of impact of varints 
##Download dbsnp 
wget https://data.broadinstitute.org/snowman/hg19/Homo_sapiens_assembly19.dbsnp138.vcf
wget https://data.broadinstitute.org/snowman/hg19/Homo_sapiens_assembly19.dbsnp138.vcf.idx
mv *.vcf *.idx $HOME/LongRead/Reference/
##Install whatshap 
pip install whatshap==2.3
