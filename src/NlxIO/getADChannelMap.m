function [macroChannelMap, microChannelMap] = getADChannelMap(montageConfigFile)

    if isempty(montageConfigFile)
        [macroChannelMap, microChannelMap]  = deal([]);
        return;
    end
    
    montageConfig = readJson(montageConfigFile);
    macroChannelsList = {};
    macroChannelsAD = [];
    % handle macros
    numMacrosAdded = 0;
    for macroGroupIdx = 1: length(montageConfig.macroChannels)
        currentMacroGroup = montageConfig.macroChannels(macroGroupIdx);
        currentMacroGroup = currentMacroGroup{1, 1};
        macroGroupName = currentMacroGroup{1, 1};
        groupStartIdx = currentMacroGroup{2, 1};
        groupEndIdx = currentMacroGroup{3, 1};
        
        for currentMacroIdx = groupStartIdx : groupEndIdx
            currentMacroNumber = currentMacroIdx - groupStartIdx + 1;
            %currentMacroName = macroGroupName + string(currentMacroNumber);
            currentMacroName = {[macroGroupName, num2str(currentMacroNumber)]};
            currentMacroADChannel = currentMacroIdx - 1;
            numMacrosAdded = numMacrosAdded + 1;
            
            macroChannelsList(numMacrosAdded) = currentMacroName;
            macroChannelsAD(numMacrosAdded) = currentMacroADChannel;
    
        end
    
    
    
    end
    macroChannelMap = dictionary(macroChannelsAD, macroChannelsList);
    
    
    % handle micros
    microChannelsList = {};
    microChannelsAD = [];
    headStages = fieldnames(montageConfig.Headstages);
    currentMicroAD = 128;
    if isfield(montageConfig, 'MicroChannelStart')
        currentMicroAD = montageConfig.MicroChannelStart;
    end
    numMicrosAdded = 0;
    for headStageIdx  = 1 : length(headStages)
        currentBankName = headStages{headStageIdx};
        ports = fieldnames(montageConfig.Headstages.(currentBankName));
        if isempty(ports)
            currentMicroAD = currentMicroAD + 32;
        end
        for portIdx = 1 : length(ports)
            currentPortName = ports{portIdx};
            currentMicroBundleInfo = montageConfig.Headstages.(currentBankName).(currentPortName);
            numMicrosInBundle = currentMicroBundleInfo.Micros;
            microBundleName = currentMicroBundleInfo.BrainLabel;
    
            for microIdx = 1 : numMicrosInBundle
                currentMicroName = {[currentBankName, replace(currentPortName, 'Port', ''), '-', microBundleName, num2str(microIdx)]};
                currentMicroADChannel = currentMicroAD + (microIdx - 1);
                numMicrosAdded = numMicrosAdded + 1;
                microChannelsList(numMicrosAdded) = currentMicroName;
                microChannelsAD(numMicrosAdded) = currentMicroADChannel;
            end
            currentMicroAD = currentMicroAD + 8;
        end
    
        
    
    
    end
    
    
    microChannelMap = dictionary(microChannelsAD, microChannelsList);
end
