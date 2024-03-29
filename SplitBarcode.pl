#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;
use FileHandle;
my $usage=<<USAGE;
	Usage:
		perl $0 [options]
			*-r1 --read1 <string>		read1.fq.gz
			 -r2 --read2 <string>		read2.fq.gz, if not provided, it will be SE
			 -e  --errNum <int>		mismatch number [default: 2 for PE, 1 for SE]
			*-f  --firstCycle <int>		first cylce of barcode
			*-b  --barcodeList <string>	barcodes list
			 -rc --revcom	<Y|N>		generate reverse complement of barcode.list or not [default: Y]
			 -c  --compress <Y|N>		compress(.gz) output or not [default: Y]
			 -o  --outdir <string>		output directory [default: ./]
			 -h  --help			print help information and exit
	Example:
		perl $0 -r1 read1.fq.gz -r2 read2.fq.gz -e 2 -f 101 -b barcode.list -o /path/outdir
		perl $0 -r1 read1.fq.gz -e 1 -f 101 -b barcode.list -o /path/outdir
		Modified by Jin Xu for 10X scATAC, keep barcode information as I1 and R3. 	
	============barcode.list===========
	#barcodeName	barcodeSeq
	1	ATGCATCTAA
	2	AGCTCTGGAC
	===================================
USAGE

#=============global variants=============
my ($read1,$read2,$errNum,$fc,$bl,$compress,$outdir,$rc,$help);
my (%bchash,$prefix,$ambo1,$ambo2i);
#=========================================
GetOptions(
	"read1|r1=s"=>\$read1,
	"read2|r2:s"=>\$read2,
	"errNum|e:i"=>\$errNum,
	"firstCycle|f=i"=>\$fc,
	"barcodeList|b=s"=>\$bl,
	"revcom|rc:s"=>\$rc,
	"compress|c:s"=>\$compress,
	"outdir|o:s"=>\$outdir,
	"help|h:s"=>\$help
);
#$errNum ||= 2 if $read2;
#$errNum ||= 1 unless $read2;
if(defined $errNum && $errNum == 0){
	$errNum=0;
}
elsif(!defined $errNum ){
	$errNum ||= 2 if $read2;
	$errNum ||= 1 unless $read2;
}
#if ($os eq 'linux'){
$outdir ||= `pwd`;
#}
#elsif($os eq 'MSWin32'){
#	$outdir ||= `echo %cd%`;
#}
$compress ||= 'Y';
$rc ||= 'Y';

if(!$read1 || !$fc || !$bl || $help ){
	die "$usage";
}

#========global variables==========
my (%barhash,%oh,%oribar,%correctBar,%correctedBar,%unknownBar,$totalReadsNum);
my (%tagNum,$am1,$am2,@fq,$barcode_len);
#=========================
if($read2){
	my $name=basename($read2);
	$prefix=$1 if $name=~/(.*)\_(\w+)_2\.fq(.gz)?/;	# V300009631_128A_L01_read_2.fq.gz
}else{
	my $name=basename($read1);
	$prefix=$1 if $name=~/(.*)\_(\w+)\.fq(.gz)?/;	# S100004580_38_L01_read.fq.gz
}
unless(-d $outdir){
	print STDERR "$outdir: No such directory, but we will creat it\n";
	`mkdir -p $outdir`;
}
$outdir=abs_path($outdir);
print STDERR "==================important information===============\n";
print STDERR "read 1:\t$read1\nread 2:\t$read2\n" if $read2;
print STDERR "read 1:\t$read1\n" unless $read2;
print STDERR "output directory:\t$outdir\nmismatch number:\t$errNum\nfirst cycle number:\t$fc\n";
print STDERR "======================================================\n";
chomp($outdir);
open my $fh,$bl or die "$bl No such file, check it !\n$!";
if($read2){
	open $am1,">$outdir/$prefix\_unbarcoded_1.fq" or die $!;
	open $am2,">$outdir/$prefix\_unbarcoded_2.fq" or die $!;
	push @fq,"$outdir/$prefix\_unbarcoded_1.fq";
	push @fq,"$outdir/$prefix\_unbarcoded_2.fq";
}
else{
	open $am1,">$outdir/$prefix\_unbarcoded.fq" or die $!;
	push @fq,"$outdir/$prefix\_unbarcoded.fq";
}
open my $BS,">$outdir/BarcodeStat.txt" or die $!;
open my $SS,">$outdir/TagStat.txt" or die $!;

print $BS "#SpeciesNO\tCorrect\tCorrected\tTotal\tPct\n";
print $SS "#Sequence\tSpeciesNO\treadCount\tPct\n";

while(<$fh>){	#1	ATGCATCTAA
	next if /^#/;
	chomp;
	my @tmp=split /\s+/,$_;
	if(uc($rc) eq 'Y'){
		$tmp[1]=reverse(uc($tmp[1]));
		$tmp[1]=~tr/ATCGN/TAGCN/;
	}else{
		$tmp[1]=uc($tmp[1]);
	}
	$oribar{$tmp[1]} =1;
	$barcode_len=length($tmp[1]);
	&bar_hash($tmp[1],$tmp[0],$errNum,\%barhash);
	if($read2){
		open $oh{$barhash{$tmp[1]}}[0],"| gzip >$outdir/$prefix\_$tmp[0]\_R1.fq.gz" or die $!;
		open $oh{$barhash{$tmp[1]}}[1],"| gzip >$outdir/$prefix\_$tmp[0]\_R3.fq.gz" or die $!;
		open $oh{$barhash{$tmp[1]}}[2],"| gzip >$outdir/$prefix\_$tmp[0]\_I1.fq.gz" or die $!;
		open $oh{$barhash{$tmp[1]}}[3],"| gzip >$outdir/$prefix\_$tmp[0]\_R2.fq.gz" or die $!;
		push @fq,"$outdir/$prefix\_$tmp[0]\_R1.fq.gz";
		push @fq,"$outdir/$prefix\_$tmp[0]\_R3.fq.gz";
#		push @fq,"$outdir/$prefix\_$tmp[0]\_I1.fq.gz";
#		push @fq,"$outdir/$prefix\_$tmp[0]\_R3.fq.gz";
	}else{
		open $oh{$barhash{$tmp[1]}}[0],"| gzip >$outdir/$prefix\_$tmp[0].fq.gz" or die $!;
		push @fq,"$outdir/$prefix\_$tmp[0].fq.gz";
	}
}
close $fh;
my($rd1,$rd2);
if($read2){
	if($read2=~/fq$/){
		open $rd1,$read1 or die $!;
		open $rd2,$read2 or die $!;
	}
	elsif($read2=~/fq.gz$/){
		#open $rd1,"gzip -dc $read1|" or die $!;
		#open $rd2,"gzip -dc $read2|" or die $!;
		open $rd1,"zcat $read1|" or die $!;	#suggested by shengqin
	}   open $rd2,"zcat $read2|" or die $!;	#suggested by shengqin
}
else{
	if($read1 =~/fq$/){
		open $rd1,$read1 or die $!;
	}
	elsif($read1 =~/fq.gz$/){
		#open $rd1,"gzip -dc $read1|" or die $!;
		open $rd1,"zcat $read1|" or die $!;	#suggested by shengqin
	}
}
if($read2){
	while(<$rd1>){
		my $head1= $_;
		$head1=~s/\/1/ 1:N:0:0/;
		my $seq1 = <$rd1>;
		my $plus1= <$rd1>;
		my $qual1= <$rd1>;
		my $head2= <$rd2>;
		   $head2=~s/\/2/ 3:N:0:0/;
		my $seq2 = <$rd2>;
		my $plus2= <$rd2>;
		my $qual2= <$rd2>;
		$totalReadsNum ++;
		chomp($head1,$seq1,$plus1,$qual1,$head2,$seq2,$plus2,$qual2);
		my $barseq=substr($seq2,$fc-1,$barcode_len+1);
		$tagNum{$barseq} ++;
		if(exists $barhash{$barseq}){
			# seqeunce removed barcode , first 50bp
			my $spitseq2=substr($seq2,0,50);
			my $spitqual2=substr($qual2,0,50);
			# barcode : last 8 bp. 
			my $barcode=substr($seq2,$fc-1,$barcode_len+1);
			my $barqual=substr($qual2,$fc-1,$barcode_len+1);
			my $random=substr($seq2,50,16);
			my $randomqual=substr($qual2,50,16);
			#my $fh1=$oh{$barhash{$barseq}}[0];my$fh2=$oh{$barhash{$barseq}}[1];
		
			$oh{$barhash{$barseq}}[0]->print("$head1\n$seq1\n$plus1\n$qual1\n"); # R1 
			$oh{$barhash{$barseq}}[1]->print("$head2\n$spitseq2\n$plus2\n$spitqual2\n"); # R3
			$head2=~s/3:N:0:0/2:N:0:0/; # this is important for  Cell Ranger
			#print $head2,"\n";
			$oh{$barhash{$barseq}}[2]->print("$head2\n$barcode\n$plus2\n$barqual\n"); # I1
			$head2=~s/2:N:0:0/4:N:0:0/; # this is important for Cell Ranger
			$oh{$barhash{$barseq}}[3]->print("$head2\n$random\n$plus2\n$randomqual\n"); # R2
			#print $fh1 "$head1\n$seq1\n$plus1\n$qual1\n";
			#print $fh2 "$head2\n$spitseq2\n$plus2\n$spitqual2\n";
			if(exists $oribar{$barseq}){
				$correctBar{$barhash{$barseq}} +=1;
			}
			else{
				$correctedBar{$barhash{$barseq}} +=1;
			}
		}
		else{	#unbarcoded
			#my $spitseq2=substr($seq2,0,$fc-1).substr($seq2,$fc+$barcode_len-1,);
			#my $spitqual2=substr($qual2,0,$fc-1).substr($qual2,$fc+$barcode_len-1,);
			print $am1 "$head1\n$seq1\n$plus1\n$qual1\n";
			#print $am2 "$head2\n$spitseq2\n$plus2\n$spitqual2\n";
			print $am2 "$head2\n$seq2\n$plus2\n$qual2\n";	
			$unknownBar{$barseq} +=1;
		}
	}
	close $rd1;close $rd2;
	close $am1;close $am2;
}else{
	while(<$rd1>){
		my $head1= $_;
		   #$head1=~tr/\1/ 1:N:0:0/; #
		my $seq1 = <$rd1>;
		my $plus1= <$rd1>;
		my $qual1= <$rd1>;
		$totalReadsNum ++;
		chomp($head1,$seq1,$plus1,$qual1);
		my $barseq=substr($seq1,$fc-1,$barcode_len+1);
		$tagNum{$barseq} ++;
		if(exists $barhash{$barseq}){
			my $spitseq1=substr($seq1,0,$fc-1).substr($seq1,$fc+$barcode_len-1,);
			my $spitqual1=substr($qual1,0,$fc-1).substr($qual1,$fc+$barcode_len-1,);
			$oh{$barhash{$barseq}}[0]->print("$head1\n$spitseq1\n$plus1\n$spitqual1\n");
			if(exists $oribar{$barseq}){
				$correctBar{$barhash{$barseq}} +=1;
			}else{
				$correctedBar{$barhash{$barseq}} +=1;
			}
		}
		else{
			print $am1 "$head1\n$seq1\n$plus1\n$qual1\n";
		}
	}
	close $rd1;close $am1;
}

my($totalcorrect,$totalcorrected,$totalbarreads,$totalpct);
for my $seq(sort {$barhash{$a} cmp $barhash{$b}} keys %oribar){
	my $BartotalReads = $correctBar{$barhash{$seq}}+$correctedBar{$barhash{$seq}};
	my $pct = ($BartotalReads/$totalReadsNum)*100;
	$totalcorrect += $correctBar{$barhash{$seq}};
	$totalcorrected+=$correctedBar{$barhash{$seq}};
	$totalbarreads += $BartotalReads;
	$totalpct += $pct;
	#print $BS "$barhash{$seq}\t$correctBar{$seq}\t$correctedBar{$seq}\t$BartotalReads\t$pct\n";
	printf $BS "%s\t%d\t%d\t%d\t%.4f%%\n",$barhash{$seq},$correctBar{$barhash{$seq}},$correctedBar{$barhash{$seq}},$BartotalReads,$pct;
}
#print $BS "Total\t$totalcorrect\t$totalcorrected\t$totalbarreads\t$totalpct\n";
printf $BS "Total\t%d\t%d\t%d\t%.4f%%\n",$totalcorrect,$totalcorrected,$totalbarreads,$totalpct;
close $BS;

for my $seq(sort {$tagNum{$b}<=>$tagNum{$a}} keys %tagNum){
	my $pct=($tagNum{$seq}/$totalReadsNum)*100;
	if(exists $barhash{$seq}){
		#print $SS "$seq\t$barhash{$seq}\t$tagNum{$seq}\t$pct\n";
		printf $SS "%s\t%s\t%d\t%.2f%%\n",$seq,$barhash{$seq},$tagNum{$seq},$pct;
	}
	else{
		#print $SS "$seq\tunknown\t$tagNum{$seq}\t$pct\n";
		printf $SS "%s\tunknown\t%d\t%.2f%%\n",$seq,$tagNum{$seq},$pct;
	}
}
close $SS;

#=============subroutine==================
sub bar_hash{
	my ($seq,$name,$errnum,$hash)=@_;
	my ($tmp_seq);
	my @bases=('A','T','C','G','N');
	if($errnum==0){
		$hash->{$seq} =$name;
		return $hash;
	}else{
		for (my $i=0;$i<length($seq);$i++){
			for (my $j=0;$j<@bases;$j++){
				$tmp_seq =substr($seq,0,$i).$bases[$j].substr($seq,$i+1,);
				if($errnum > 1){
					&bar_hash($tmp_seq,$name,$errnum-1,$hash);
				}
				else{
					$hash->{$tmp_seq}=$name;
				}
			}
		}
		return $hash;
	}
}
