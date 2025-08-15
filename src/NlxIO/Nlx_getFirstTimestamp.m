function startTimestamp = Nlx_getFirstTimestamp(fileName, isNev)
    startTimestamp = uint64(0);
    
    skipBytes = 16384;
    if nargin > 1 && isNev
        skipBytes = skipBytes + 6;
    end
    
    fid = fopen(fileName, 'r');
    header = fread(fid, skipBytes, '*uchar');
    raw = fread(fid, 8, '*uchar');
    fclose(fid);
    for rawIndex = 1:length(raw)
        startTimestamp = bitsll(startTimestamp,8);
        startTimestamp = startTimestamp + uint64(raw(length(raw) - rawIndex + 1));
    end


    
    %startTimestamp = datetime(startTimestamp, 'ConvertFrom', 'posixtime');
    
end