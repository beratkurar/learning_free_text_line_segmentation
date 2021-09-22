function [charsRange] = estimateCharsHeight(I,bin,options)
%berat begin
%to eliminate stopping em, don't include images with less than 10
%components
%components=bwconncomp(bin);
%berat end

% Binary Image.
if (islogical(I))% || components.NumObjects<10)
    [lower,upper] = estimateBinaryHeight(bin,options.thsLow,options.thsHigh,options.Margins);
    fprintf('binary image so mean used')
    disp([lower,upper])
else    
    if (options.EMEstimation)
        try
            EvolutionMapDirectory = 'EvolutionMap\';
            EMResult = [EvolutionMapDirectory, 'estimateCharacterDimensions.exe',' ','"',options.partsPath,...
                '/',options.partName,'"'];
            [~,cmdout] = system( EMResult);
            res = sscanf(cmdout,'(%f,%f)\n(%f,%f)');
        catch
            fprintf('evolution map catched')
            res=[];
        end
    end  
    % Evolution map is turned off or failed to execute.
    if (~options.EMEstimation || isempty(res) || res(3) == 0)
        [lower,upper] = estimateBinaryHeight(bin,options.thsLow,options.thsHigh,options.Margins);
        fprintf('   em error or option so mean used\n')
        disp([lower,upper])    
    else         
        lower = res(3);
        upper = res(4);
        fprintf('em used')
        disp([lower,upper])          
    end
end

% better version: thinner blobs safer for touching blob lines
lower = lower/2;
upper = upper/2;

% conference version:
charsRange = [lower,upper];

fprintf('actually used')
disp([lower,upper])
end
