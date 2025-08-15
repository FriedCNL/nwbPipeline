% configurations of pipeline:
% see: getNeuralynxFiles.m

MACRO_FILE_PATTERN = '^[RL].*[0-9]*.ncs';
MICRO_FILE_PATTERN = '^G[A-D]-*.ncs';

IGNORE_FILES = {
    '^A1.*\.ncs';
    '^A2.*\.ncs';
    '^C3.*\.ncs';
    '^C4.*\.ncs';
    '^F3.*\.ncs';
    '^F4.*\.ncs';
    '^EMG.*\.ncs';
    '^EOG.*\.ncs';
    '^Analogue1.*\.ncs';
    '^Analogue2.*\.ncs';
    '^Analogue3.*\.ncs';
    '^Ez.*\.ncs';
    '^HR_Ref.*\.ncs';
    '^HR.ncs'
    '^MICROPHONE.*\.ncs';
    '^PZ.*\.ncs';
    '^CSC.*\.ncs'; % unknown file in iowa data.
    '^Inpt.*\.ncs';
};
