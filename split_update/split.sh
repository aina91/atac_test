#PBS -N split_ATAC
#PBS -q core24
#PBS -l mem=30gb,walltime=999:00:00,nodes=1:ppn=1

#PBS -o split_ATAC.log

#PBS -e split_ATAC.err

#PBS -V
#HSCHED -s Project_name+Software_Name+Species

##HSCHED -s hschedd
export PATH=/asnas/jiangl_group/aina/project/split/atac:$PATH
cd /asnas/jiangl_group/liyun/atac_1_20191020/L01
/asnas/jiangl_group/aina/project/split/atac/SplitBarcode.pl -r1 /asnas/jiangl_group/liyun/atac_1_20191020/L01/V300034875_L01_read_1.fq.gz  -r2 /asnas/jiangl_group/liyun/atac_1_20191020/L01/V300034875_L01_read_2.fq.gz -f 67 -e 2 -b /asnas/jiangl_group/aina/project/split/atac/ATAC_sample_index.txt  -rc N -o /asnas/jiangl_group/aina/project/split/atac/split_sample -c Y

