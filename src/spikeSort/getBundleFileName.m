function out = getBundleFileName(microFileName)

    [filePath, fileName, ext] = fileparts(microFileName);
    fileName = regexprep(fileName, '(G[A-D][1-9]-).*(_00[1-9])', ['$1', 'bundleMedian', '$2']);
    out = fullfile(filePath, 'bundleMedian', [fileName, ext]);

end