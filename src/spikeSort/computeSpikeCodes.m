function spikeCodes = computeSpikeCodes(spikes, spikeTimestamps, par, inputStruct)
% spikeTimestamp should be in seconds.

if isempty(spikeTimestamps)
    warning('no spikes detected!')
    spikeCodes = [];
    return
end

w_pre = par.w_pre;
% Calculate and store spike features that can be used for rejection
spikeCodes = table();

ts = single(spikeTimestamps(:));
if length(unique(ts)) ~= length(spikeTimestamps)
    spikeCodes.timestamp_sec = spikeTimestamps(:);
else
    spikeCodes.timestamp_sec = ts;
end

spikeCodes.firingRateAroundSpikeTime = calculateFiringRate(spikeTimestamps);

% local minima:
spikeCodes.rawAmplitude = spikes(:, w_pre);
spikeCodes.ampAsMultipleOfSTD = spikes(:, w_pre) / inputStruct.noise_std_detect;
locMin = diff(sign(diff(spikes')))'>0;
locMin = [ones(size(locMin,1),1), locMin, ones(size(locMin,1),1)];

localMinInd_Pre = nan(size(spikeCodes.rawAmplitude));
localMinV_Pre = localMinInd_Pre;

localMinInd_Post = nan(size(spikeCodes.rawAmplitude));
localMinV_Post = localMinInd_Post;
halfWidth = localMinInd_Pre;

for i = 1:length(localMinInd_Pre)
    localMinInd_Pre(i) = find(locMin(i,1:w_pre-1), 1, 'last');
    localMinV_Pre(i) = spikes(i, localMinInd_Pre(i));
    localMinInd_Post(i) = find(locMin(i, w_pre+1:end), 1, 'first') + w_pre;
    localMinV_Post(i) = spikes(i, localMinInd_Post(i));
    halfHeight = (spikes(i,w_pre) - localMinV_Pre(i))/2;
    [~,halfHeightPreInd] = min(abs(spikes(i, localMinInd_Pre(i):w_pre) - halfHeight));
    halfHeightPreInd = halfHeightPreInd + localMinInd_Pre(i);
    [~,halfHeightPostInd] = min(abs(spikes(i,w_pre:localMinInd_Post(i)) - halfHeight));
    halfHeightPostInd = halfHeightPostInd + w_pre-1;
    halfWidth(i) = halfHeightPostInd - halfHeightPreInd;
end

spikeCodes.heightToWidthRatio = spikes(:,w_pre)./halfWidth;
spikeCodes.minToMinWidth = localMinInd_Post-localMinInd_Pre;
spikeCodes.localMinInd_Pre = localMinInd_Pre;
spikeCodes.localMinV_Pre = localMinV_Pre;
spikeCodes.localMinInd_Post = localMinInd_Post;
spikeCodes.localMinV_Post = localMinV_Post;
spikeCodes.halfWidth = halfWidth;

end

function firingRateAroundSpikeTime = calculateFiringRate(spikeTimestamps)
    % convert spike time stamps to milliseconds:
    spikeTimestamps = (spikeTimestamps - spikeTimestamps(1)) * 1000 + 250;
    maxSpikeTs = max(spikeTimestamps);

    binEdges1 = 0:500:(500*floor(maxSpikeTs/500)+500);
    hist1 = histcounts(spikeTimestamps, binEdges1);
    idx1 = min(floor(spikeTimestamps/500) + 1, length(hist1));
    spikeCount1 = hist1(idx1);

    binEdges2 = binEdges1 + 250;
    hist2 = histcounts(spikeTimestamps, binEdges2);
    idx2 = min(floor((spikeTimestamps-250)/500) + 1, length(hist2));
    idx2 = max(idx2, 1);
    spikeCount2 = hist2(idx2);

    firingRateAroundSpikeTime = .5 * max([spikeCount1(:), spikeCount2(:)], [], 2);
end
