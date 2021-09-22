function [result,Labels, linesMask, newLines,upperHeight] = ExtractLines(I, bin, varargin)
    if (nargin == 2)
        fprintf('the options changed'+nargin)
        options = struct('EuclideanDist',true, 'mergeLines', true, 'EMEstimation',false,... 
            'cacheIntermediateResults', false, 'thsLow',10,'thsHigh',100,'Margins', 0.2);
    else
        options = varargin{1};
    end
    charRange=estimateCharsHeight(I,bin,options);
    if (isnan(charRange(1)))
        charRange=[13,16];
    end
    upperHeight=charRange(2);
    if (options.cacheIntermediateResults &&...
            exist([options.dstPath,'masks/',options.sampleName,'.png'], 'file') == 2)
        linesMask = imread([dstPath,'masks/',sampleName,'.png']);
    else
        %conference version
        linesMask = LinesExtraction(~bin, charRange(1):charRange(2));
        %try version
        %linesMask = LinesExtraction(I, charRange(1):charRange(2));
    end
    [L,num] = bwlabel(bin);
    if ((num<=2)||~any(linesMask(:)))
        fprintf('no component or no blob line \n')
        result=L;
        Labels=0;
        newLines=zeros(size(bin));
    else 
        [result,Labels,newLines] = PostProcessByMRF(L,num,linesMask,charRange,options);
    end
end
