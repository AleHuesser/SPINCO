#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
---------------------------------------------------------------------------------------------------------------------
 CREATE A SUMMARY REPORT 
---------------------------------------------------------------------------------------------------------------------  
* Reads MNE epoched objects. 
* Makes a report for quality assessment and results inspection 
* 
@author: gfraga
Created on Tue Dec  6 15:03:56 2022
"""
import mne
from mne.time_frequency import tfr_morlet
import os
from glob import glob
import numpy as np
import pickle
# %  Access epoched data
dir_epoched = '/home/d.uzh.ch/gfraga/smbmount/spinco_data/SINEEG/DiN/data_preproc_ep_ICrem/epochs/'
diroutput = '/home/d.uzh.ch/gfraga/smbmount/spinco_data/SINEEG/DiN/'
if not os.path.exists(diroutput): 
    os.mkdir(diroutput)
    
files = glob(dir_epoched + "s*.fif", recursive=True)
subjects = [f.split('/')[-1].split('_')[0] for f in files ]


#Specify conditions and group of conditions to average to: 
condition_sets = {'corr': ['corr/easy','corr/mid','corr/hard'],
           'incorr':['incorr/easy','incorr/mid','incorr/hard'],
            'easy':['corr/easy','incorr/easy'],
            'mid':['corr/mid','incorr/mid'],
            'hard':['corr/hard','incorr/hard'],
            'clear':['corr/clear','incorr/clear']}  
# %%  Create dict 
groupEvoked = {}
groupPower = {}
groupTFR = {}
for idx,set in enumerate(condition_sets):
    epochs = []; evokeds = []; averageTFRs = [];power= []
    for f in files: 
        ep = mne.read_epochs(f)[condition_sets[set]]
        evk = ep.average()
        evk.info['description'] = f
        
        epochs.append(ep)
        evokeds.append(evk)
            
        #spectrum 
        spec = ep.compute_psd()
        spec.info['description']= f
        power.append(spec)

        # Time freq
        freqs = np.logspace(*np.log10([1, 48]), num=56)
        n_cycles = freqs / 2.  # different number of cycle per frequency
        pwr = tfr_morlet(ep, freqs=freqs, decim= 3, n_cycles=3, average=True, use_fft=True, return_itc=False,n_jobs=4)
    
        averageTFRs.append(pwr)
     
    groupEvoked[set] = evokeds
    groupPower[set] = spec
    groupTFR[set] = averageTFRs
     
    
# %% 
os.chdir(diroutput)
try: 
    filehandler = open('groupTFR', 'wb')
    pickle.dump(groupTFR, filehandler)
except:
    print('failed to write file')
    
try: 
    filehandler = open('groupPower', 'wb')
    pickle.dump(groupPower, filehandler)
except:
    print('failed to write file')


try: 
    filehandler = open('groupEvoked', 'wb')
    pickle.dump(groupEvoked, filehandler)
except:
    print('failed to write file')
        
    #groupEvoked[set] =  [mne.read_epochs(f)[condition_sets[set]].average() for f in files]
        