function experimentID = getExperimentIDFromPath(filepath)
    try
        experimentID = str2num(cell2mat(regexp( filepath, '(?<=Experiment-)\d+', 'match')));
    catch
        experimentID = -1;
    end
end

