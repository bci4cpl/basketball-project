function [ALLEEG, EEG, CURRENTSET] = check_data(ds_path,  ALLEEG, EEG)

% Global
    global SHOTS_TYPE;
    global GO_Q;
    global BALL_RELEASE;
    global SHOTS_LATENCY_INTERVAL;

% Constants
    SHOTS_TYPE = [4 5 6];
    GO_Q = 2;
    BALL_RELEASE = 3;
    SHOTS_LATENCY_INTERVAL = 900;
    SAPMLE_RATE = 300;
    MIN_DIF_BETWEEN_GO_AND_RELEASSE_SEC = 0.6;
    MAX_DIF_BETWEEN_GO_AND_RELEASSE_SEC = 2;
    MIN_DIF_BETWEEN_GO_AND_RELEASSE_TPNT = MIN_DIF_BETWEEN_GO_AND_RELEASSE_SEC * SAPMLE_RATE; 
    MAX_DIF_BETWEEN_GO_AND_RELEASSE_TPNT = MAX_DIF_BETWEEN_GO_AND_RELEASSE_SEC * SAPMLE_RATE;
    
    DATASET_NAME_CONVENTION = "subSUB_TRIAL_rawData";
% Epochs constants
    T_START = -2.4; % time of beginning of short epoch in sec.
    T_END = 0.05; % time of end of long short in sec.
if ~exist('ALLEEG', 'var')
	[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
else
	[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
end

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

[EEG.event(:).SR] = deal(0); [EEG.event(:).Class] = deal(0);
t = num2cell(1:size(EEG.event,2)/2);
t2 = extractfield(EEG.event,'type'); t2 = (t2==2);
[EEG.event(t2).SR] = t{:};
t3 = [EEG.event(~t2).type]; t3 = num2cell(t3);
[EEG.event(t2).Class] = t3{:};
EEG.etc.logger.eventsPreTimeDiff = EEG.event;
% EEG = Utils.DS.checkGOToReleaseTimeDiff (EEG, MIN_DIF_BETWEEN_GO_AND_RELEASSE_TPNT, MAX_DIF_BETWEEN_GO_AND_RELEASSE_TPNT);
% EEG = Utils.DS.deleteEventTypes (EEG, ALLEEG, CURRENTSET, 1); % leaves only trials that meet time condition.

EEG.etc.logger.eventsPreAlign = EEG.event;


EEG = Utils.DS.aligningEvents(EEG);
EEG = pop_rmdat( EEG, {'3' '8' '9'},[-4 0.06] ,0); % cutting data by event
EEG = Utils.DS.strToDoubleEvent(EEG); %change event type back to double


EEG.etc.logger.eventsPostAlign = EEG.event;


EEG = Utils.DS.creatingEpochs(EEG, ALLEEG, CURRENTSET, T_START, T_END, file_name);
EEG.etc.logger.eventsPostEpochs = EEG.event;
end
    