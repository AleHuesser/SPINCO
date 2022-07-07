clear all ; 
% ========================================================================
%  Generate Speech-shaped noise   
% ========================================================================
% Author: G.FragaGonzalez 2022(based on snippets from T.Houweling)
% Description
%   - Reads single wav or list of .wav files (concatenate if multiple)
%   - Filters signal (butterworth) 
%   - Uses filtered signal to create speech shaped noise (calls function)
%   - Normalization: matches Root Mean Square of noise to signal RMS
%   - Several plots signal and noise (in one figure)
%
%-------------------------------------------------------------------------
% add paths of associated functions and toolbox TSM required by function 
addpath('V:\gfraga\scripts_neulin\Noise_generation\functions')
addpath('C:\Program Files\MATLAB\R2021a\toolbox\MATLAB_TSM-Toolbox_2.03')
 %% Inputs 
dirinput = 'V:\gfraga\SPINCO\Sound_files\Digits_16k\' ;
diroutput = 'V:\gfraga\SPINCO\Sound_files\Digits_16k\';

% files full path
wavfiles = dir([dirinput, '*Speaker01*.wav']);
wavfiles = fullfile(dirinput, {wavfiles.name});

% Filter settings (butterworth filter lower and upper cut freqs in Hz) 
filt_low = 50 ;
filt_upper = 5000;
    
% Parameters for SSN function 
nfft = 1000;
srate = 16000;
noctaves = 6;   % 1/6 octave band smoothing (spectral smoothing in which the bandwidth of the smoothing window is a constant percentage of the center frequency).

%% Read and concatenate 
% check files 
tmp = contains(wavfiles,'.wav','ignorecase',true);
if (~isempty(find(tmp~=1,1)))
    error('your input list must contain only .wav filenames !') 
else 
    disp(['Reading ', num2str(length(wavfiles)),' files (.wav)...'])
end

% Read wavs and concatenate (if multiple)
amps = cell(length(wavfiles),1);
frqs = cell(length(wavfiles),1);
for i=1:length(wavfiles)        
    [amps{i},frqs{i}] = audioread(wavfiles{i});
    if size(amps{i},2)>1 
         error('Check: multiple channels present in the file?') 
    end 
end
sourceSignal = vertcat(amps{:});
if ~isrow(sourceSignal); sourceSignal=sourceSignal';end 

%  CHECK: are sampling rates the same ? 
if ~isempty(find(diff(cell2mat(frqs))~=0,1))
    error ('sampling rates seem to differ!') 
end

%% Filter 
NyqFreq = srate/2;            % fs = 2kHz; Nyquist freq. = 1 kHz
[filt_b,filt_a]=butter(3, [filt_low filt_upper]/NyqFreq);
sourceSignal_filt = filtfilt(filt_b,filt_a,sourceSignal);   % use fvtool(b,a) if you want to visualise the filter

%plot data before and after and plot filter
fig_filter = subplot(1,2,1);plot(sourceSignal);subplot(1,2,2);plot(sourceSignal_filt);
fvtool(filt_b,filt_a)
close all 

%% Introduce starting noise 

%%  INTRODUCE RAMP 


%

%% Noise 
 % speech-shape noise 
 ssn = speechshapednoise(sourceSignal_filt,nfft,noctaves,srate);     
 
 %normalize 
 ssn_norm = normalize_rms(sourceSignal_filt, ssn); 
 
 % Add to speech: speech in speech-shaped noise 
 SiSSN = sourceSignal_filt + ssn_norm;

%% Retrieve the individual segments in noise 
    % Find duration of each file
    lengths= cell(length(wavfiles),1);
    for i=1:length(wavfiles)        
        [amp,frq] = audioread(wavfiles{i});
        lengths{i} = length(amp);
    end
    endpoints = [0;cumsum(cell2mat(lengths))]; 
    % Segmented concatenated signal 
    segmented = cell(length(endpoints)-1,1);
    for j = 1:length(endpoints)-1
        
        segmented{j,1} = SiSSN(1+endpoints(j):endpoints(j+1));
        %save audio
        [pthstr, name , ext] = fileparts(wavfiles{j});
        outputfilename = strrep([diroutput,'SiSSN_',name,ext],'\\','\');
        audiowrite(outputfilename, segmented{j,1},srate)
        disp(['saved ',outputfilename]);
        
        % save a summary figure 
         segment2plot = segmented{j,1};
         original2plot = audioread(wavfiles{j})';
         variables = {'original2plot','segment2plot'};
         figure ('position', [1 1 800 800],'color','white'); 
            % Amplitude x  time 
            titles = {'original','SiSSN(norm)'};    
            for p = 1:2
                subplot(3,2,p);
                plot(eval(variables{p}))
                title(titles{p});  ylabel('Amplitude (a.u.)');  xlabel('Time (ms)');    
            end     
            % Spectral plots
            titles = {'LTAS original','LTAS SiSSN (norm)'};
             for p = 1:2    
                subplot(3,2,2+p);
                iosr.dsp.ltas(eval(variables{p}),srate,'noct',noctaves,'graph',true,'units','none','scaling','max0','win',srate/10);  % requires the IoSR Matlab Toolbox
                xline(50, '--k'); xline(5000, '--k'); 
                title(titles{p});
             end 
            % Surf plots
            titles = {'Spectrogram original)', 'Spectrogram SiSSN(norm)'};
            for p = 1:2
                subplot(3,2,4 + p);
                parameter = [];           
                parameter.fsAudio = srate;
                parameter.zeroPad = srate/10;
                [spec2plot,f,t] = stft(eval(variables{p})',parameter);
                surf(t(2:end-3),f(1:round(length(f)/2)+1),abs(spec2plot(1:round(length(f)/2)+1,2:end-3)));
                hold on; set(gcf,'renderer','zbuffer'); shading interp; view(0,90); axis tight; caxis([0 50])
                title(titles{p});
            end
 
            print(gcf, '-djpeg', strrep(outputfilename,'.wav','.jpg'));
            disp(['...saved figure for ',outputfilename]);
            close gcf
    end
     
 %% Plots  
    % Amplitude x time plots 
    figure ('position', [1 1 800 800],'color','white'); 
    variables = {'sourceSignal_filt','ssn_norm','SiSSN'};
    titles = {'Speech signal (filt)','SSN norm','Speech in SSN'};    
    for p = 1:3
        subplot(3,3,p);
        plot(eval(variables{p}))
        title(titles{p});
        ylabel('Amplitude (a.u.)');
        xlabel('Time (s)');    
    end     
    % Spectral plots
    titles = {'LTAS of speech (filt))','LTAS of SSN norm','LTAS of SiSSN'};
     for p = 1:3    
        subplot(3,3,3+p);
        iosr.dsp.ltas(eval(variables{p}),srate,'noct',noctaves,'graph',true,'units','none','scaling','max0','win',srate/10);  % requires the IoSR Matlab Toolbox
        xline(50, '--k'); xline(5000, '--k'); 
        title(titles{p});
    
     end 
    % Surf plots
    titles = {'Spectrogram of speech (filt)', 'Spectrogram of SSN norm', 'Spectrogram of SiSSN'};
    for p = 1:3
        subplot(3,3,6 + p);
        parameter = [];
        parameter.fsAudio = srate;
        parameter.zeroPad = srate/10;
        [spec2plot,f,t] = stft(eval(variables{p})',parameter);
        surf(t(2:end-3),f(1:round(length(f)/2)+1),abs(spec2plot(1:round(length(f)/2)+1,2:end-3)));
        hold on; set(gcf,'renderer','zbuffer');
        shading interp; view(0,90); axis tight;
        caxis([0 50])
        title(titles{p});
    end
 
    %% save summary plot 
    %save audio
    [pthstr, name , ext] = fileparts(wavfiles{j});
    outputfilename = strrep([diroutput,'SiSSN.wav'],'\\','\');
    audiowrite(outputfilename, SiSSN,srate)
    disp(['saved ',outputfilename]);
    
    % save picture 
     print(gcf, '-djpeg', strrep(outputfilename,'.wav','.jpg'));
     disp(['...saved figure for ',outputfilename]);
    close gcf