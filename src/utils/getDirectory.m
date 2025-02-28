function workingDir = getDirectory()

    if ismac
        % Code to run on Mac platform
        userHomeDir = getenv('HOME');
        workingDir = fullfile(userHomeDir, 'HoffmanMount/data/PIPELINE_vc/ANALYSIS');
    elseif isunix
        % Code to run on Linux platform
        userHomeDir = getenv('HOME');
        workingDir = '/u/project/ifried/data/PIPELINE_vc/ANALYSIS/';
    else
        error(['getDirecotry only supports Mac and Linux platforms.\n' ...
            'You need to set working directory in the script or batch job']);
    end

end
