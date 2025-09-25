function bundleMedianFiles = calculateBundleMedian(microFiles, skipExist)

if nargin < 2
    skipExist = true;
end

channelsPerBundle = 8;
runRemovePLI = false;
numBundles = ceil(size(microFiles, 1) / channelsPerBundle);
nSegments = size(microFiles, 2);
bundleMedianFiles = cell(numBundles, size(microFiles, 2));

parfor i = 1: numBundles
    for j = 1: nSegments
        bundleStartIdx = (i-1) * channelsPerBundle + 1;
        bundleMicroFiles = microFiles(bundleStartIdx:bundleStartIdx+channelsPerBundle-1, j);
        
        bundleMedianFileName = getBundleFileName(bundleMicroFiles{1});

        if skipExist && exist(bundleMedianFileName, "file")
            fprintf('skip exist file: %s\n', bundleMedianFileName);
            continue;
        end

        if ~exist(bundleMicroFiles{1}, "file")
            fprintf('skip non-exist file: %s\n', bundleMicroFiles{1});
            continue;
        end
        
        fprintf('process: %s\n', bundleMicroFiles{:});

        signal = readCSC(bundleMicroFiles{1}, runRemovePLI, true);
        cscLength = length(signal);
        bundleMicroCSC = nan(channelsPerBundle, cscLength);
        if not(all(signal==0))
            bundleMicroCSC(1, :) = signal(:)';
        end

        for k = 2:channelsPerBundle
            signal = readCSC(bundleMicroFiles{k}, runRemovePLI, true);
            if not(all(signal==0)) % to account for empty files eg 1789 exp101 LSMG8_003/4
                bundleMicroCSC(k, :) = signal(:)';
            end
        end
        
        bundleMedian = single(nanmedian(bundleMicroCSC, 1));
        fprintf('save bundle meadian file: %s.\n', bundleMedianFileName);
        bundleMedianFileNameTemp = strrep(bundleMedianFileName, '.mat', '_temp.mat');
        if exist(bundleMedianFileNameTemp, "file")
            delete(bundleMedianFileNameTemp);
        end
        bundleMedianFileObj = matfile(bundleMedianFileNameTemp, "Writable", true);
        bundleMedianFileObj.bundleMedian = bundleMedian(:);
        movefile(bundleMedianFileNameTemp, bundleMedianFileName)
    end
end

end
