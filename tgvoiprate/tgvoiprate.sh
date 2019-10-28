#!/bin/bash
### Command arguments can be accessed as

if [ ! -f $1 ]; then
        echo "$1 File not found!"
        exit 1
fi

if [ ! -f $2 ]; then          
        echo "$2 File not found!"
        exit 1
fi
 

filename_one=$(basename $1)
fname_one="${filename_one%.*}"


filename_two=$(basename $2)
fname_two="${filename_two%.*}"

#### pip3 install

python3 -c "import librosa" > /dev/null 2>&1
retVal=$?
if [ $retVal -eq 1 ]; then
        pip3 install librosa > /dev/null 2>&1
        echo ".. installing library .."
fi

if [ ! -f $fname_one.txt ]; then
        opusdec $filename_one ${fname_one}_copy.opus  --save-range  $fname_one.txt > /dev/null 2>&1
fi
if [ ! -f $fname_two.txt ]; then
        opusdec $filename_two ${fname_two}_copy.opus  --save-range  $fname_two.txt > /dev/null 2>&1
fi

cat << 'EOF' > ./tgvoiprate_exe.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
flt=0.17 #frames difference
loss_trashold=0.5  #max difference for frames in file1 and file2
cost_trashold=0.15 #quality parameter for the cost function
dct=0.5 #delta cost function
corr_trashold=0.95
#ent=0.01 #noise treshold
hop_length=64 #distance between frames (for energy estimation only)
frame_length=512 # frame length (for energy estimation only)

import numpy as np
import librosa as lr
import random
import pandas as pd
import sys

file1 = sys.argv[1]
file2 = sys.argv[2]
file3 = sys.argv[3]
file4 = sys.argv[4]


def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError:
        return ""

def readfiledata(file1,file2):
    
       
    #first file
    df1=pd.read_csv(file1,header=None)
    df2=pd.read_csv(file2,header=None)
    
    pblist=[]
    pb=df1[3].tolist()
    
    for item in pb:
        v=find_between(item,' ',']')
        pblist.append(v)
        
    fqlist=[]
    fq=df1[8].tolist()
    
    for item in fq:
        v=find_between(item,' ',']')
        fqlist.append(v)
    
    fb1 = list(map(int, pblist))
    fq1= list(map(int, fqlist))
    
    
    pblist=[]
    pb=df2[3].tolist()

    for item in pb:
        v=find_between(item,' ',']')
        pblist.append(v)
    
    fqlist=[]
    fq=df2[8].tolist()

    for item in fq:
        v=find_between(item,' ',']')
        fqlist.append(v)

    fb2 = list(map(int, pblist))
    fq2= list(map(int, fqlist))
    
    fb1.sort(reverse = True)
    fb2.sort(reverse = True)
    fq1.sort(reverse = True)
    fq2.sort(reverse = True)
    k=len(fb1)-len(fb2)
    if k>= 0:
        fb2.extend([2 for i in range(k)])
        fq2.extend([2**24 for i in range(k)])
    else:
        fb1.extend([2 for i in range(-k)])  
        fq1.extend([2**24 for i in range(-k)])
    k=abs(k)
    r=k/len(fb1)
    return fb1,fb2,fq1,fq2,r

def find_corr(list1,list2):
    corr=np.corrcoef(list1,list2)
    cor=corr[0,1]
    return cor

def cost_func(file3,file4):
    y1, sr1 = lr.load(file3)
    y2, sr2 = lr.load(file4)
    X1 = lr.feature.chroma_cens(y=y1, sr=sr1)
    X2 = lr.feature.chroma_cens(y=y2, sr=sr2)
    D, wp = lr.sequence.dtw(X1, X2, subseq=True)
    cost=D[-1, :] / wp.shape[0]
    mincost=min(cost)
    d_cost=max(cost)-min(cost)
    fl=abs((y1.shape[0]-y2.shape[0])/y1.shape[0])
    return mincost, d_cost, fl

def set_estimation(r,fl,cor,loss_trashold,cost_trashold,mincost,d_cost,corr_trashold,flt,dct):
    
    bigloss= r>loss_trashold
    bigframediff=fl > flt
    bigcostfunmin=mincost > cost_trashold
    smallcostfundelta=d_cost > dct
    goodcorr=cor>corr_trashold
    
    if  (not bigloss) & (not bigframediff) &  (not bigcostfunmin) & smallcostfundelta & goodcorr:
        rate=5+random.random()
        return rate
    if  (not bigloss)  & (not bigframediff) & (not bigcostfunmin) & smallcostfundelta:
        rate=4+random.random()
        return rate
    if  (not bigloss)  & (not bigframediff) & bigcostfunmin:
        rate=3+random.random()
        return rate
    if  (not bigloss)  &  bigframediff:
        rate=2+random.random()
        return rate
    if  bigloss:
        rate=1+random.random()
        return rate
    
fb1,fb2,fq1,fq2,r=readfiledata(file1,file2)

cor=find_corr(fb1,fb2)

mincost, d_cost, fl= cost_func(file3,file4)     
     
rate= set_estimation(r,fl,cor,loss_trashold,cost_trashold,mincost,d_cost,corr_trashold,flt,dct)  

print(rate)
EOF

chmod 755 tgvoiprate_exe.py

./tgvoiprate_exe.py $fname_one.txt $fname_two.txt $filename_one $filename_two 2> /dev/null

rm -rf tgvoiprate_exe.py
#rm -rf $fname_one.txt
#rm -rf $fname_two.txt
rm -rf ${fname_one}_copy.opus
rm -rf ${fname_two}_copy.opus

exit 0
