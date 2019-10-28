#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 25 14:07:40 2019
.
tgvoiprate /path/to/sound_A.opus /path/to/sound_output_A.opus
4.6324
If for some reason you can't avoid external dependencies, you may list them in a text file (see deb-packages.txt below).
 These dependencies will be installed using sudo apt-get install ... before your app is tested. Available package names
 and versions can be found here.

The resulting audio file will be offered to a group of testers, who will rate their quality with integers from 0 to 6.
then compute the modified mean squared error of the application's rating from the mean human ratings using the 
formula sum(max(|x_i - y_i| - 0.3, 0.0)^2).

file1 (file_in.txt) - text opus file for origin file3  created with opusenc --save-range
file2 (file_out.txt)- text opus file for damaged file4 created with opusdec --save-range
file3 (file_origin.opus) - origin file
file4 (file_damaged.opus) - damaged file


@author: innerm
"""

"""" key constants """

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



#def normalize(x, axis=0):
#    return sklearn.preprocessing.minmax_scale(x, axis=axis)


#def strip(x, frame_length, hop_length):
#
#    # Compute RMSE.
#    rms = lr.feature.rms(x, frame_length=frame_length, hop_length=hop_length, center=True)
#    
#    # Identify the first frame index where RMSE exceeds a threshold.
#    thresh = 0.01
#    frame_index = 0
#    while rms[0][frame_index] < thresh:
#        frame_index += 1
#        
#    # Convert units of frames to samples.
#    start_sample_index = lr.frames_to_samples(frame_index, hop_length=hop_length)
#    
#    # Return the trimmed signal.
#    return x[start_sample_index:]


def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError:
        return ""

""" get data from opus files"""

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

""" calculate noice for origin file """
  
#def Energy_RMS(file,hop_length,frame_length):
#    x, sr = lr.load(file)
#    energy = np.array([
#        sum(abs(x[i:i+frame_length]**2))
#        for i in range(0, len(x), hop_length)
#    ])
#    
#    rms = lr.feature.rms(x, frame_length=frame_length, hop_length=hop_length, center=True)
#    rms = rms[0]
#    mEn=min(energy)
#    mRMS=(min(rms))
#    return mEn, mRMS


""" calculate pearson correlation for the frame vectors """

def find_corr(list1,list2):
    corr=np.corrcoef(list1,list2)
    cor=corr[0,1]
    return cor

""" calculate rate for file in 1-5 range """

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
    
    
    
   
        
        
""" test estimation """

#file1 = '/home/innerm/voip/pl/sw_in.txt'
#file2 = '/home/innerm/voip/pl/file4.txt'
#file3 = '/home/innerm/voip/pl/sw/sw.ogg'
#file4 = '/home/innerm/voip/pl/sw/sw_pl_25.ogg'

fb1,fb2,fq1,fq2,r=readfiledata(file1,file2)

cor=find_corr(fb1,fb2)

mincost, d_cost, fl= cost_func(file3,file4)     
     
rate= set_estimation(r,fl,cor,loss_trashold,cost_trashold,mincost,d_cost,corr_trashold,flt,dct)  

#bigloss
#bigframediff
#bigcostfunmin
#smallcostfundelta
#goodcorr

print('r:',r,loss_trashold)
print('fl:',fl,flt)
print('mincost:',mincost,cost_trashold)
print('d_cost:',d_cost,dct)
print('corr:',cor,corr_trashold)

print('rate',rate)

