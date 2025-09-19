function debugPlotIEDMetrics(obj, data, sleepScoringVec, suspectTimesMs)
% DEBUGPLOTIEDMETRICS  Visualize IED detection metrics over time using SpikeWaveDetectorClass settings.
% Usage:
%   debugPlotIEDMetrics(obj, data)
%   debugPlotIEDMetrics(obj, data, sleepScoringVec)
%   debugPlotIEDMetrics(obj, data, sleepScoringVec, suspectTimesMs)

    if nargin < 3 || isempty(sleepScoringVec), useSleep = false; else, useSleep = true; end
    if nargin < 4, suspectTimesMs = []; end

    sr   = obj.samplingRate;
    T    = numel(data);
    tsec = (0:T-1)./sr;

    data = data(:)';                 % row
    data_orig = data;
    data_mask = data;

    % Sleep masking (like detectTimes)
    if useSleep
        data_mask(sleepScoringVec(:)' ~= obj.NREM) = 0;
    end

    % Replace NaNs with 0 for processing
    data_mask(isnan(data_mask)) = 0;

    % Global amplitude z-score over masked data (matches detectTimes)
    zsAmp_all = zscore(data_mask);

    % Holders
    zsEnv_all    = nan(1, T);
    zsGrad_all   = nan(1, T);
    pass_env     = false(1, T);
    pass_env_lo  = false(1, T);
    pass_amp     = false(1, T);
    pass_amp_lo  = false(1, T);
    pass_grad    = false(1, T);
    pass_grad_lo = false(1, T);
    pass_conj_ag = false(1, T);
    pass_conj_ae = false(1, T);
    pass_final   = false(1, T);

    ptsPerBlock  = obj.blockSizeSec * sr;
    nBlocks      = floor(T / ptsPerBlock);

    detected_peaks = [];

    for iBlock = 1:nBlocks
        idx0 = (iBlock-1)*ptsPerBlock + 1;
        idx1 = iBlock*ptsPerBlock;
        block = data_mask(idx0:idx1);
        nB = numel(block);

        % Amplitude (global z, abs for thresholds)
        if obj.useAmp || obj.useConjAmpGrad || obj.useConjAmpEnv
            zsAmp = zsAmp_all(idx0:idx1);
            pts_amp    = abs(zsAmp) > obj.SDthresholdAmp;
            pts_amp_lo = abs(zsAmp) > obj.SDthresholdConjAmp;
        else
            pts_amp    = repmat(~obj.isDisjunction, 1, nB);
            pts_amp_lo = false(1, nB);
        end

        % Gradient (per-block z)
        if obj.useGrad || obj.useConjAmpGrad
            grad = [0, diff(block)];
            zsG = zscore(grad);
            pts_g    = zsG > obj.SDthresholdGrad;
            pts_g_lo = zsG > obj.SDthresholdConjGrad;
        else
            zsG      = nan(1, nB);
            pts_g    = repmat(~obj.isDisjunction, 1, nB);
            pts_g_lo = false(1, nB);
        end

        % HP envelope (per-block z)
        if obj.useEnv || obj.useConjAmpEnv
            hp   = obj.bandpass(block, sr, obj.lowCut, obj.highCut);
            envB = abs(hilbert(hp));
            zsE  = zscore(envB);
            pts_e    = zsE > obj.SDthresholdEnv;
            pts_e_lo = zsE > obj.SDthresholdConjEnv;
        else
            zsE      = nan(1, nB);
            pts_e    = repmat(~obj.isDisjunction, 1, nB);
            pts_e_lo = false(1, nB);
        end

        % Conjunction masks (low thresholds)
        if obj.useConjAmpGrad, pts_ag = pts_amp_lo & pts_g_lo; else, pts_ag = false(1, nB); end
        if obj.useConjAmpEnv,  pts_ae = pts_amp_lo & pts_e_lo; else, pts_ae = false(1, nB); end

        % Final pointwise pass
        if obj.isDisjunction
            pts_final = pts_e | pts_g | pts_amp | pts_ag | pts_ae;
        else
            pts_final = pts_e & pts_g & pts_amp;
        end

        % Save
        zsEnv_all(idx0:idx1)    = zsE;
        zsGrad_all(idx0:idx1)   = zsG;
        pass_env(idx0:idx1)     = pts_e;
        pass_env_lo(idx0:idx1)  = pts_e_lo;
        pass_amp(idx0:idx1)     = pts_amp;
        pass_amp_lo(idx0:idx1)  = pts_amp_lo;
        pass_grad(idx0:idx1)    = pts_g;
        pass_grad_lo(idx0:idx1) = pts_g_lo;
        pass_conj_ag(idx0:idx1) = pts_ag;
        pass_conj_ae(idx0:idx1) = pts_ae;
        pass_final(idx0:idx1)   = pts_final;

        % Recreate peaks for plotting
        if any(pts_final)
            blkPeaks = localPeaksFromMask(block, pts_final, obj.samplingRate, ...
                                            obj.minLengthSpike, obj.maxLengthSpike, obj.minDistSpikes);
            if ~isempty(blkPeaks)
                detected_peaks = [detected_peaks, (blkPeaks + idx0 - 1)];
            end
        end
    end

    % --------- Plots
    figure('Name','IED metrics debug','Color','w');
    tiledlayout(5,1,'Padding','compact','TileSpacing','compact');

    % 1) Raw
    nexttile;
    plot(tsec, data_orig, 'k'); hold on;
    if ~isempty(detected_peaks), xline((detected_peaks-1)./sr, ':', 'Detected', 'Alpha', 0.5); end
    if ~isempty(suspectTimesMs), xline(suspectTimesMs./1000, '--', 'Suspect', 'Color', [0.2 0.4 0.9], 'Alpha', 0.8); end
    ylabel('uV'); title('Raw signal'); xlim([tsec(1), tsec(end)]); grid on;

    % 2) HP env z
    nexttile;
    plot(tsec, zsEnv_all, 'r'); hold on;
    yline(obj.SDthresholdEnv,   'k-',  'Env thr');
    yline(obj.SDthresholdConjEnv,'k--','Env low');
    if ~isempty(detected_peaks), xline((detected_peaks-1)./sr, ':'); end
    if ~isempty(suspectTimesMs), xline(suspectTimesMs./1000, '--'); end
    ylabel('z(HP env)'); title('High-pass envelope z-score'); xlim([tsec(1), tsec(end)]); grid on;

    % 3) Amp z
    nexttile;
    plot(tsec, zsAmp_all, 'b'); hold on;
    yline(obj.SDthresholdAmp,   'k-',  'Amp thr');
    yline(obj.SDthresholdConjAmp,'k--','Amp low');
    if ~isempty(detected_peaks), xline((detected_peaks-1)./sr, ':'); end
    if ~isempty(suspectTimesMs), xline(suspectTimesMs./1000, '--'); end
    ylabel('z(Amp)'); title('Amplitude z-score (global on masked data)'); xlim([tsec(1), tsec(end)]); grid on;

    % 4) Grad z
    nexttile;
    plot(tsec, zsGrad_all, 'g'); hold on;
    yline(obj.SDthresholdGrad,    'k-',  'Grad thr');
    yline(obj.SDthresholdConjGrad,'k--','Grad low');
    if ~isempty(detected_peaks), xline((detected_peaks-1)./sr, ':'); end
    if ~isempty(suspectTimesMs), xline(suspectTimesMs./1000, '--'); end
    ylabel('z(Grad)'); title('Gradient z-score'); xlim([tsec(1), tsec(end)]); grid on;

    % 5) Pass masks (distinct colors)
    nexttile; hold on;
    % Distinct colors for each mask
    plot(tsec, double(pass_env),     '-', 'DisplayName','Env pass',        'Color', [0.75 0.00 0.20]);
    plot(tsec, double(pass_amp),     '-', 'DisplayName','Amp pass',        'Color', [0.00 0.45 0.74]);
    plot(tsec, double(pass_grad),    '-', 'DisplayName','Grad pass',       'Color', [0.20 0.60 0.20]);
    plot(tsec, double(pass_env_lo),  '-', 'DisplayName','Env low pass',    'Color', [1.00 0.55 0.00]);
    plot(tsec, double(pass_amp_lo),  '-', 'DisplayName','Amp low pass',    'Color', [0.30 0.75 0.93]);
    plot(tsec, double(pass_grad_lo), '-', 'DisplayName','Grad low pass',   'Color', [0.47 0.67 0.19]);
    plot(tsec, double(pass_conj_ag), '-', 'DisplayName','Amp&Grad low',    'Color', [0.49 0.18 0.56]);
    plot(tsec, double(pass_conj_ae), '-', 'DisplayName','Amp&Env low',     'Color', [0.93 0.69 0.13]);
    plot(tsec, double(pass_final),   '-', 'DisplayName','Final pass',      'Color', [0.00 0.00 0.00], 'LineWidth', 1.2);

    ylim([-0.2 1.2]); yticks([0 1]); yticklabels({'no','yes'});
    xlabel('Time (s)'); ylabel('Pass?'); title(sprintf('Pass masks (isDisjunction=%d)', obj.isDisjunction));
    if ~isempty(detected_peaks), xline((detected_peaks-1)./sr, ':'); end
    if ~isempty(suspectTimesMs), xline(suspectTimesMs./1000, '--'); end
    grid on; xlim([tsec(1), tsec(end)]);
    legend('Location','northeastoutside');

    ax = findall(gcf,'Type','axes'); linkaxes(ax,'x');


end


function blkPeaks = localPeaksFromMask(block, mask, sr, minLenMs, maxLenMs, minDistMs)
    % convert ms->samples
    minLen  = max(1, round(minLenMs  * sr / 1000));  % at 2 kHz: 1 ms -> 2 samples
    maxLen  = round(maxLenMs * sr / 1000);
    minDist = round(minDistMs* sr / 1000);

    % find contiguous runs where mask==1
    d = diff([false, mask, false]);
    starts = find(d==1);
    ends   = find(d==-1) - 1;

    % enforce min length
    lens = ends - starts + 1;
    keep = lens >= minLen;
    starts = starts(keep); ends = ends(keep);

    % merge runs with small gaps (<= minDist)
    if ~isempty(starts)
        M_st = []; M_en = [];
        st = starts(1); en = ends(1);
        for k = 2:numel(starts)
            if (starts(k) - en - 1) <= minDist
                en = ends(k);                % merge
            else
                M_st(end+1) = st; %#ok<AGROW>
                M_en(end+1) = en; %#ok<AGROW>
                st = starts(k); en = ends(k);
            end
        end
        M_st(end+1) = st; M_en(end+1) = en;
        starts = M_st; ends = M_en;
    end

    % drop overly long runs (> maxLen)
    if ~isnan(maxLen)
        lens = ends - starts + 1;
        keep = lens <= maxLen;
        starts = starts(keep); ends = ends(keep);
    end

    % choose “peak” as argmax of the raw block within each run (matches class)
    blkPeaks = zeros(1, numel(starts));
    for k = 1:numel(starts)
        [~, idx] = max(block(starts(k):ends(k)));
        blkPeaks(k) = starts(k) + idx - 1;
    end
end
