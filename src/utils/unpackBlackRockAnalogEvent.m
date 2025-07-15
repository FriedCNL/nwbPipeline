function unpackBlackRockAnalogEvent(input_fname, output_fname)
    ttlCode = [];
    ts = [];
    
    load(input_fname);
    
    voltage_diff = diff(data);
    threshold = 10000;
    state = 0;
    num_ttls = 0;
    for i = 1:length(voltage_diff)
        
        if state == 0

            if voltage_diff(i) >= threshold
                num_ttls = num_ttls + 1;
                ttlCode(num_ttls, 1) = 1;
                ts(num_ttls, 1) = (i - 1) * seconds(samplingInterval);
                state = 1;
            end
        else
            if voltage_diff(i) <= (-1 * threshold)
                state = 0;
            end

        end

    end

    outFileObj = matfile(output_fname, "Writable", true);
    outFileObj.TTLs = ttlCode;
    outFileObj.timestamps = ts;

end