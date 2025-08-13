function ADChannel = Nlx_getADChannel(fileName)
    ADChannel = -1;

    fid = fopen(fileName, 'r');
    raw = fread(fid, 16384, '*uchar')';
    fclose(fid);
    header = string(char(raw));
    ADChannel = regexp(header,'(?<=ADChannel\s)[\d]+','match');
    ADChannel = str2num(ADChannel{1});

end