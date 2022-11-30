import os
import numpy as np
from glob import glob
import scipy.io as sio
import mne 
import pandas as pd
from mne.time_frequency import tfr_morlet

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 31 10:26:03 2022
   
# PREPARE A MATRIX FOR SVM 
 #------------------------------------
   # We need an .m file with: 
   # Input data should be in the form of a .mat file containing four structs
       # S : array of size 1 x total number of trials; containing participant numbers corresponding to all trials
       # X : array of size number of channels x number of time points x number of trials; contains preprocessed channel voltage data at each time point for each trial
       # Y : array of size 1 x total number of trials; containing condition labels corresponding to all trials
       # times : array of size 1 x number of time points; contains all time points in the epoch of interest
   
    # In this case we use time frequency power (power averaged across several frequency bins)
    
@author: gfraga
"""

home = os.path.expanduser("~")

#% Gather Target File info
# %------------------------
basedirinput  = '/home/d.uzh.ch/gfraga/smbmount/spinco_data/SINEEG/DiN/data_preproc_ep_ICrem/epochs/' 
diroutput = '/home/d.uzh.ch/gfraga/smbmount/spinco_data/SINEEG/DiN/mvpa/25subj_TFR_2' 
if not os.path.exists(diroutput): 
    os.mkdir(diroutput)


os.chdir(basedirinput)        
# find target files
files = glob(basedirinput + "*.set", recursive=True)
# Retrieve list of subjects name from folder structure
subjects = [fullpath.split('/')[-1].split('_')[0] for fullpath in files]

files = files[-8:] # temmporary trim due to memory issues 
print(files) 
# Info about conditions
conditions = ['corr/clear','incorr/clear','corr/easy','incorr/easy','corr/mid','incorr/mid','corr/hard','incorr/hard']


# %% # Loop thru files

for fileinput in files: 
    print (fileinput)
    slist= []
    ylist = []
    #--------------------------------------------------------    

    # Read Epochs in MNE 
    epochs = mne.io.read_epochs_eeglab(fileinput)       
    #Read matlab file for addutional time and trial info 
    mdat = sio.loadmat(fileinput,squeeze_me = True,simplify_cells = True,mat_dtype=True)['EEG']
       
    # Time adjustment
    epochs.shift_time(mdat['actualTimes']/1000-epochs.times)[0]
    
    # Retrieve trial accuracy
    epochAccu = [epoch['accuracy'] for epoch in mdat['epoch']]
    
    # degradation levels    
    epochDeg = [epoch['degBin'] for epoch in mdat['epoch']]
    epochDeg = [0 if x!=x else x for x in epochDeg] # replace nan by 0 
        
    
    # recode events in MNE-read data
    for epIdx in range(len(epochs.events)):
        epochs.events[epIdx][2]=epochAccu[epIdx]*10 + epochDeg[epIdx]
    
    # add event information 
    epochs.event_id = {'corr/clear': 10,'corr/easy': 11,'corr/mid': 12,'corr/hard': 13,'incorr/clear': 0,'incorr/easy': 1,'incorr/mid': 2,'incorr/hard': 3}

 
    # % TIME FREQ  Gather time freq power per epoch ------------------- -
    freqs = np.logspace(*np.log10([1, 48]), num=56)
    n_cycles = freqs / 2.  # different number of cycle per frequency
    power = tfr_morlet(epochs, freqs=freqs, decim= 3, n_cycles=3, average=False, use_fft=True, return_itc=False,n_jobs=4)
    
    # Extract frequency bands:
    df = power.to_data_frame(time_format=None)  
    freq_bounds = {'_': 0,
                   'delta': 4,
                   'theta': 8,
                   'alpha': 13,
                   'beta': 35,
                   'gamma': 140}
    
    df['band'] = pd.cut(df['freq'], list(freq_bounds.values()),
                    labels=list(freq_bounds)[1:])
       
    # Filter to retain only relevant frequency bands:
    freq_bands_of_interest = ['alpha']
    df = df[df.band.isin(freq_bands_of_interest)]
    df['band'] = df['band'].cat.remove_unused_categories()
    
    # Mean 
    dfmean = df.groupby(['epoch','time']).mean() # add mean per time point of all freqs selected across a selected set of channels
        
    #% Append reshaping into a large array with channels x time point x trials matrix    
    x = []
    epIds = dfmean.index.get_level_values('epoch').unique()
    for ep in epIds:
        thisEpoch = dfmean.filter(regex='^E.*',axis = 1 ).loc[ep].to_numpy().transpose()
        x.append(thisEpoch)
        del thisEpoch        
    
    X = np.dstack(x)      
        
    # Gather output arrays ----------------------------------------------------------------    
    subjectNum = int(fileinput.split('/')[-1].split('_')[0].replace('s',''))    
    
    # Subject info: subject number repeated n trial times 
    slist.append ([subjectNum]*X.shape[2])
    
    #Condition info 
    ylist.append ([int(n) for n in epochAccu])    
    
    # get times 
    times =  df['time'].unique() # contain info about time points (the same in all files)
    preproc_mvpa = {'S':slist, 'Y':ylist,'times':times}
    
    
   
    # SAVE stuff --------------------------------------------------------------- 
    sio.savemat((diroutput + '/s'+ str(subjectNum)+'_prep4mvpa.mat'),{'x':X})  
    sio.savemat(diroutput + '/' + fileinput.split('/')[-1].split('_')[0] + '_info_trials_mvpa.mat',preproc_mvpa)
   
    del X, df, dfmean, mdat,epochs, power, times, preproc_mvpa, slist, ylist