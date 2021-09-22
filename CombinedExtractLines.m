function [result,Labels, linesMask, newLines] = CombinedExtractLines(I, bin, whole_blob_lines,varargin)
    if (nargin == 2)
        fprintf('the options changed'+nargin)
        options = struct('EuclideanDist',true, 'mergeLines', true, 'EMEstimation',false,... 
            'cacheIntermediateResults', false, 'thsLow',0,'thsHigh',Inf,'Margins', 0);
    else
        options = varargin{1};
    end
    charRange=estimateCharsHeight(I,bin,options);
    if (isnan(charRange(1)))
        charRange=[13,16];
    end
    if (options.cacheIntermediateResults &&...
            exist([options.dstPath,'masks/',options.sampleName,'.png'], 'file') == 2)
        linesMask = imread([dstPath,'masks/',sampleName,'.png']);
    else
        %linesMask = LinesExtraction(I, charRange(1):charRange(2));
        linesMask = whole_blob_lines;
    end
    [L,num] = bwlabel(bin);
    if (num<=2)
        fprintf('only one component \n')
        result=L;
        Labels=1;
        newLines=ones(size(bin));
    else
        [result,Labels,newLines] = PostProcessByMRF(L,num,linesMask,charRange,options);
    end
end
