function timestampIndex = findTimestampIndex(timestampVal,timestampArr, timestampDiffEps, startIdx, endIdx)
    
    if isempty(timestampArr)
        timestampIndex = -3;
        return;
    end
    if nargin < 4
        startIdx = 1;
    end
    if nargin < 5
        endIdx = length(timestampArr);
    end
    if(timestampVal < timestampArr(startIdx)) && (timestampVal - timestampArr(startIdx)) < (-1 * timestampDiffEps)
         timestampIndex = -1;
         return;
     end
     if(timestampVal > timestampArr(endIdx))
         timestampIndex = -2;
         return;
     end

    if (timestampArr(startIdx) - timestampVal) >= 0 && (timestampArr(startIdx) - timestampVal) <= timestampDiffEps
        timestampIndex = startIdx;
        return;
    end
    if (timestampArr(endIdx) - timestampVal) >= 0 && (timestampArr(endIdx) - timestampVal) <=  timestampDiffEps
        timestampIndex = endIdx;
        return;
    end   
    
    if (endIdx - startIdx) < 2
        timestampIndex = endIdx;
        return;
    end

    midpt = floor((startIdx + endIdx) / 2);
    if (timestampArr(midpt) - timestampVal) <  timestampDiffEps
        timestampIndex = findTimestampIndex(timestampVal,timestampArr, timestampDiffEps, midpt, endIdx);
        return;
    else
        timestampIndex = findTimestampIndex(timestampVal,timestampArr, timestampDiffEps, startIdx, midpt);
        return;
    end


end

