
function [EEG] = preprocess_pipeline(cfg, ds_path, dest_dir, ALLEEG, EEG)
% preprocess_pipeline - pipeline function. accepts a dataset ('.set') file
% path, a destination directory for auto saving, ALLEEG and EEG.


%%%%%%% Experiment parameters %%%%%%%

% Global
    global SHOTS_TYPE;
    global GO_Q;
    global BALL_RELEASE;
    global SHOTS_LATENCY_INTERVAL;

% Constants
    SHOTS_TYPE = cfg.Constants.SHOTS_TYPE;
    GO_Q = cfg.Constants.GO_Q;
    BALL_RELEASE = cfg.Constants.BALL_RELEASE;
    SHOTS_LATENCY_INTERVAL = cfg.Constants.SHOTS_LATENCY_INTERVAL;
    SAPMLE_RATE = cfg.Constants.SAPMLE_RATE;
    MIN_DIF_BETWEEN_GO_AND_RELEASSE_SEC = cfg.Constants.MIN_DIF_BETWEEN_GO_AND_RELEASSE_SEC;
    MAX_DIF_BETWEEN_GO_AND_RELEASSE_SEC = cfg.Constants.MAX_DIF_BETWEEN_GO_AND_RELEASSE_SEC;
    MIN_DIF_BETWEEN_GO_AND_RELEASSE_TPNT = MIN_DIF_BETWEEN_GO_AND_RELEASSE_SEC * SAPMLE_RATE; 
    MAX_DIF_BETWEEN_GO_AND_RELEASSE_TPNT = MAX_DIF_BETWEEN_GO_AND_RELEASSE_SEC * SAPMLE_RATE;
    
% Epochs constants
    T_START = cfg.Epochs.T_START; % time of beginning of short epoch in sec.
    T_END = cfg.Epochs.T_END; % time of end of long short in sec.

    % setting 'the jump' event true a false.
    APPLY_EVENTS_ALIGNMENT = cfg.Epochs.APPLY_EVENTS_ALIGNMENT;
    
%%%%%%% Pipeline parameters %%%%%%%

% Double percision parameters
    APPLY_DOUBLE_PERCISION = cfg.General.APPLY_DOUBLE_PERCISION;

% Resampling parameters
    APPLY_RESAMPLING = cfg.Resampling.APPLY_RESAMPLING;
    RESAMPLING_RATE = cfg.Resampling.RESAMPLING_RATE;

% Filter parameters
    LOW_CUTOFF = cfg.Filter.LOW_CUTOFF;
    HIGH_CUTOFF = cfg.Filter.HIGH_CUTOFF;
    APPLY_HIGHPASS_FILTER = cfg.Filter.APPLY_HIGHPASS_FILTER;
    APPLY_LOWPASS_FILTER = cfg.Filter.APPLY_LOWPASS_FILTER;
    APPLY_BAND_FILTER = cfg.Filter.APPLY_BAND_FILTER;

% Channloc info parameters
	APPLY_CHANLOC = cfg.Channloc.APPLY_CHANLOC;

% Cleanline parameters    
    APPLY_CLEANLINE = cfg.Cleanline.APPLY_CLEANLINE;
   
% ASR parameters
    APPLY_ASR = cfg.ASR.APPLY_ASR;
    SD_for_ASR = cfg.ASR.SD_for_ASR;
    SHOW_SPECTOPO_POST_ASR = cfg.ASR.SHOW_SPECTOPO_POST_ASR;
    Line_Noise_Criterion = cfg.ASR.Line_Noise_Criterion;
    %need more parameters

% Interpolation parameters
    APPLY_CHANNELS_INTERPOLATE = cfg.Interpolation.APPLY_CHANNELS_INTERPOLATE;

% Re-referencing to average parameters
    APPLY_REREFERENCE_TO_AVERAGE = cfg.Rereferencing.APPLY_REREFERENCE_TO_AVERAGE;
    SHOW_SPECTOPO_POST_REREFERENCE = cfg.Rereferencing.SHOW_SPECTOPO_POST_REREFERENCE;

% Remove empty epochs parameters
	APPLY_CLEAR_NAN_ELECTRODES = cfg.CleanNanElectrodes.APPLY_CLEAR_NAN_ELECTRODES;
	NAN_ELECTRODES_TH = cfg.CleanNanElectrodes.NAN_ELECTRODES_TH;
    
% Clean epochs
    MAX_BAD_CHANNEL_PER_EPOCH = cfg.CleanEpochs.MAX_BAD_CHANNEL_PER_EPOCH;
    MAX_BAD_EPOCHS_PER_CHANNEL = cfg.CleanEpochs.MAX_BAD_EPOCHS_PER_CHANNEL; % in 0 to 1 scale.
    APPLY_CLEAN_CHANNEL_BY_TH = cfg.CleanEpochs.APPLY_CLEAN_CHANNEL_BY_TH;
    NEG_TH = cfg.CleanEpochs.NEG_TH;
    POS_TH = cfg.CleanEpochs.POS_TH;
    WIN_STRAT = cfg.CleanEpochs.WIN_STRAT;
    WIN_END = cfg.CleanEpochs.WIN_END;
    APPLY_CLEAN_CHANNEL_SPECTRA_TH = cfg.CleanEpochs.APPLY_CLEAN_CHANNEL_SPECTRA_TH;
    SPECRA.method = cfg.CleanEpochs.SPECRAmethod; % wavelet or bandpower.
    SPECRA.freq_resolution = cfg.CleanEpochs.SPECRAfreq_resolution;
    SPECRA.tStart = cfg.CleanEpochs.SPECRAtStart;
    SPECRA.tEnd = cfg.CleanEpochs.SPECRAtEnd;
    NSD = cfg.CleanEpochs.NSD;
    
% Bands ranges
    bands_range.theta = cfg.BandsRange.bands_range_theta;
    bands_range.alpha = cfg.BandsRange.bands_range_alpha;
    bands_range.beta = cfg.BandsRange.bands_range_beta;
    bands = struct2cell(bands_range);
    
    
DATASET_NAME_CONVENTION = cfg.General.DATASET_NAME_CONVENTION;
%%%%%%%%%%%%%%%%%%%%%%%%%% PIPELINE start %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load eeglab
if ~exist('ALLEEG', 'var')
	[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
else
	[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
end


if APPLY_DOUBLE_PERCISION
	pop_editoptions('option_single', 0); % set option to double precision
end

% load dataset to eeglab
EEG = pop_loadset(ds_path);

[~,ds_name,~] = fileparts(ds_path);
if isempty(EEG.subject) || isempty(EEG.session)
    [sub, trail] = Utils.OS.extract_sub_trail_from_file(ds_name, DATASET_NAME_CONVENTION);
    EEG.subject = str2double(sub);
    EEG.session = str2double(trail);
else
    sub = EEG.subject;
    trail = EEG.session;
end
file_name = ['sub' sub '_' trail '_ed'];



% handle events
EEG = Utils.DS.orderingEvents(EEG); 
EEG = Utils.DS.deleteEventTypes (EEG, ALLEEG, CURRENTSET, 1); % leaves only 2->3/8/9 trials 

% issue serial numbers for events
[EEG] = Utils.DS.issue_events_serials(EEG);

EEG = Utils.DS.checkGOToReleaseTimeDiff (EEG, MIN_DIF_BETWEEN_GO_AND_RELEASSE_TPNT, MAX_DIF_BETWEEN_GO_AND_RELEASSE_TPNT);
EEG = Utils.DS.deleteEventTypes (EEG, ALLEEG, CURRENTSET, 1); % leaves only trials that meet time condition.

EEG.etc.logger.eventsPreAlign = EEG.event;

% Cleaning The Data
if APPLY_RESAMPLING
	EEG = pop_resample (EEG, RESAMPLING_RATE);          % Downsampling
end

if APPLY_HIGHPASS_FILTER
	[EEG, ALLEEG, CURRENTSET] = Utils.DS.highPass_filter(EEG, ALLEEG,  CURRENTSET, LOW_CUTOFF,  file_name);
end

if APPLY_CHANLOC
	[EEG, ALLEEG] = Utils.DS.set_chanloc(EEG, ALLEEG, CURRENTSET);
end

if APPLY_CLEANLINE
	[EEG, ALLEEG, CURRENTSET] = Utils.DS.CleanLine(EEG, ALLEEG,  CURRENTSET);
end

if APPLY_LOWPASS_FILTER
	[EEG, ALLEEG, CURRENTSET] = Utils.DS.lowPass_filter(EEG, ALLEEG, HIGH_CUTOFF, file_name);
end

if APPLY_BAND_FILTER
	[EEG, ALLEEG, CURRENTSET] = Utils.DS.bandFilteringData(EEG, ALLEEG, CURRENTSET, FREQUECY_TO_FILTER, file_name);
end

if APPLY_EVENTS_ALIGNMENT
    EEG = Utils.DS.aligningEvents(EEG);
end

EEG = pop_rmdat( EEG, {'3' '8' '9'},[-4 T_END+0.05] ,0); % cutting data by event
EEG = Utils.DS.strToDoubleEvent(EEG); %change event type back to double

if APPLY_ASR
	[EEG, EEG_org, SNR, eliminatedChannels, signal, noise] = Utils.DS.ASRCleaning (EEG, ALLEEG, CURRENTSET,...
        SD_for_ASR, Line_Noise_Criterion);
	if SHOW_SPECTOPO_POST_ASR
		figure; pop_spectopo(EEG, 1, [0      482343.3333], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
	end
end

EEG = Utils.DS.creatingEpochs(EEG, ALLEEG, CURRENTSET, T_START, T_END, file_name);
EEG.etc.logger.eventsPostEpochs = EEG.event;

if APPLY_CLEAN_CHANNEL_BY_TH
    [EEG, ALLEEG, CURRENTSET] = Utils.DS.reject_by_tresh(EEG, ALLEEG, CURRENTSET, NEG_TH, POS_TH,...
        WIN_STRAT, WIN_END, MAX_BAD_CHANNEL_PER_EPOCH, MAX_BAD_EPOCHS_PER_CHANNEL);
end
EEG.etc.logger.eventsPostCleanTH = EEG.event;

if APPLY_CLEAN_CHANNEL_SPECTRA_TH
    [EEG, ALLEEG, CURRENTSET] = Utils.DS.reject_by_spec(EEG, ALLEEG, CURRENTSET, bands, SPECRA, NSD,...
        MAX_BAD_CHANNEL_PER_EPOCH, MAX_BAD_EPOCHS_PER_CHANNEL);
end

if APPLY_CHANNELS_INTERPOLATE
	EEG = pop_interp(EEG, EEG_org.chanlocs, 'spherical');
end
EEG.etc.logger.eventsPostCleanSpectra = EEG.event;


if APPLY_REREFERENCE_TO_AVERAGE
	EEG = Utils.DS.reReferenceToAverage(EEG);
	if SHOW_SPECTOPO_POST_REREFERENCE
		figure; pop_spectopo(EEG, 1, [0      482343.3333], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
	end
end



if APPLY_CLEAR_NAN_ELECTRODES
	EEG = Utils.DS.clearEmptyEpochs(EEG, NAN_ELECTRODES_TH);
end

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_saveset( EEG, 'filename',[file_name '.set'],'filepath',tempdir); 
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

% if dest_dir is 0, we skip saving the dataset as a '.set' file.
if dest_dir~=0
    Utils.OS.copy_ds_to_userDir(file_name, tempdir, dest_dir);
end

end