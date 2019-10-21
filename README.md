# SplitBarcode 拆分文件失败
command:

./SplitBarcode.pl -r1 test_R1.fq.gz -r2 test_R2.fq.gz -f 67 -b sample_index.txt  -rc N -o ./output/

#问题：SplitBarcode.pl根据sample index 拆分fq 文件失败 ，没有match 到sample barcode .全部都被分到unbarcoded.fq文件
#### SplitBarcode.pl 删除了一些注释信息 并未修改

附 output、sample_index.txt等文件 截图供您参考

sample_index.txt
![“sample_index.txt”](https://github.com/aina91/atac_test/blob/master/sample_index.png)

结果输出目录1
![结果输出目录1](https://github.com/aina91/atac_test/blob/master/output_1.PNG)

结果输出目录2
![结果输出目录2](https://github.com/aina91/atac_test/blob/master/output_2.PNG)

BarcodeStat.txt统计结果
![BarcodeStat.txt统计结果](https://github.com/aina91/atac_test/blob/master/BarcodeStat.png)
