function [result,Labels, newLines] = ExtractLinesCombinedBlobs( bin, merged_whole_blob_labels,upperHeight, varargin)
    if (nargin == 2)
        fprintf('the options changed'+nargin)
        options = struct('EuclideanDist',true, 'mergeLines', true, 'EMEstimation',false,... 
            'cacheIntermediateResults', false, 'thsLow',10,'thsHigh',100,'Margins', 0.2);
    else
        options = varargin{1};
    end
%     charRange=estimateCharsHeight(I,bin,options);
%     if (isnan(charRange(1)))
%         charRange=[13,16];
%     end
%     if (options.cacheIntermediateResults &&...
%             exist([options.dstPath,'masks/',options.sampleName,'.png'], 'file') == 2)
%         linesMask = imread([dstPath,'masks/',sampleName,'.png']);
%     else
        %linesMask = LinesExtraction(I, charRange(1):charRange(2));
        %linesMask = LinesExtraction(~bin, charRange(1):charRange(2));
%     end
    [L,num] = bwlabel(bin);
    if (num<=2)
        fprintf('no component \n')
        result=L;
        Labels=0;
        newLines=zeros(size(bin));
    else
        [result,Labels,newLines] = PostProcessByMRFCombinedBlobs(L,num,merged_whole_blob_labels,upperHeight,options);
    end
end
