close all;

%for cbad simple.
%extract blobs of part images
%binarize part images
%combine binarized part images to have the whole binary page
%combine blobs of part images to have the blobs of the whole page
%extract line pixels using the whole binary page and the whole blobs page
orgsPath = 'sample_cropped_cbad_2017_simple_test/images/';
partsPath = 'sample_cropped_cbad_2017_simple_test/crop_text_regions/';
dstPath = 'sample_cropped_cbad_2017_simple_test/sample_cbad_result_half_refined_mean_merge_image_hysteris_itay_split/';

%thsLow and thsHigh are the boundary height values to consider when
%computing character height range from binary image.
%conference version: thsHigh=inf thsLow=0 and Margins=0
%better version: thsLow=5, thsHigh=50, Margins=0.2
%conference version: EM=True
%better version: EM=False, uses binary image to find character range
options = struct('EuclideanDist',true, 'mergeLines', true, 'EMEstimation',false,... 
    'cacheIntermediateResults', false, 'orgPath',orgsPath, 'dstPath', dstPath, 'thsLow',10,'thsHigh',100,'Margins', 0.2);

orgsDir = dir(orgsPath);
partsDir=dir(partsPath);
mkdir([dstPath,'fused_polygons']); 
mkdir([dstPath,'polygon_labels']);
mkdir([dstPath,'binary']);
mkdir([dstPath,'blob_lines']);
mkdir([dstPath,'baseline_images']);
mkdir([dstPath,'baseline_coordinates']);

tic
for orgInd = 1:length(orgsDir)
    fileName = orgsDir(orgInd).name;
    if (contains(fileName,'.jpg'))
        fprintf('%d - filename %s \n',orgInd,fileName);
        options.sampleName = fileName;
        page = imread([orgsPath,fileName]);
        [width,height,ch]=size(page);
        whole_polygon_labels=zeros(width,height);
        whole_blob_lines=zeros(width,height);
        whole_page_bin=zeros(width,height);
        part_names=dir([partsPath,'*',fileName]);
        for part_ind = 1:length(part_names)
            part_name=part_names(part_ind).name;
            fprintf('%d - partname %s \n',part_ind,part_name);
            split_part_name=split(part_name,'#');
            y=str2double(split_part_name(2));
            x=str2double(split_part_name(3));
            options.partName=part_name;
            options.partsPath=partsPath;
            part_image=imread([partsPath,part_name]);
            
            
            %Better version: itay's binarization, output is logical binary, 1 channel,
            %white on black
            part_bin = binarization(part_image,25,0);
            
            %Conference version: otsu binarization, output is logical binary, 3
            %channels, black on white
            %part_image=rgb2gray(part_image);
            %part_bin=~imbinarize(part_image);
            
            %berat begin
            %remove the part images with black on white
            number_of_fg_pixels=sum(sum(part_bin));
            [r,c]=size(part_bin);
            number_of_all_pixels=r*c;
            fg_pixel_ratio=number_of_fg_pixels/number_of_all_pixels;
            if(fg_pixel_ratio>0.5)
                part_bin(:)=0;
            end
            %berat end
            
            %[result,~, ~, newLines,upperHeight] = ExtractLines(part_image, part_bin, options);
            
            %begin of hysteris
            charRange=estimateCharsHeight(part_image,part_bin,options);
            if (isnan(charRange(1)))
                charRange=[13,16];
            end
            upperHeight=charRange(2);
            if (options.cacheIntermediateResults &&...
                    exist([options.dstPath,'masks/',options.sampleName,'.png'], 'file') == 2)
                linesMask = imread([dstPath,'masks/',sampleName,'.png']);
            else
                %linesMask = LinesExtraction(~bin, charRange(1):charRange(2));
                %conference version
                [~, ~, max_response] = filterDocument(~part_bin,charRange(1):charRange(2));
                
                %better version multi oriented
                %delta_theta = 2.5;
                %theta = 0:delta_theta:20-delta_theta;
                %[~, ~, max_response] = MS_filterDocument(~part_bin,charRange(1):charRange(2), theta);
                
                N=2.*round(charRange(2))+1;
                [~, linesMask] = NiblackPreProcess(max_response, part_bin, 2.*round(charRange(2))+1);

            end
            [L,num] = bwlabel(part_bin);
            if ((num<=2)||~any(linesMask(:)))
                fprintf('no component or no blob line \n')
                result=L;
                Labels=0;
                newLines=zeros(size(part_bin));
            else 
                [result,Labels,newLines] = PostProcessByMRF(L,num,linesMask,charRange,options);
            end
            
            %end of hyteris
            
            [part_polygon_labels] = postProcessByBoundPolygon( result);
            
%             figure
%             blended1 = imfuse(part_image,label2rgb(part_polygon_labels),'blend');  
%             imshow(blended1)
%             figure
%             blended2 = imfuse(part_image,label2rgb(newLines),'blend');  
%             imshow(blended2)
            
            [part_width,part_height]=size(part_polygon_labels);
            x_end=x+part_width;
            y_end=y+part_height;
            max_label=max(unique(whole_polygon_labels));
            new_polygon_labels=make_new_labels(part_polygon_labels,max_label);
  
            whole_polygon_lines(x:x_end-1,y:y_end-1)=new_polygon_labels;
            whole_blob_lines(x:x_end-1,y:y_end-1)=newLines;
            whole_page_bin(x:x_end-1,y:y_end-1)=part_bin;
%             figure
%             blended3 = label2rgb(whole_blob_lines);  
%             imshow(blended3)            

        end
        
        merged_whole_blob_lines=imclose(whole_blob_lines,strel(10));
        [result,Labels, newLines] = ExtractLinesCombinedBlobs(whole_page_bin,merged_whole_blob_lines,upperHeight, options);
        [whole_polygon_labels] = postProcessByBoundPolygon(result);
        %CbadSaveResults2Files(page,whole_polygon_labels,result,fileName,dstPath);
        CbadSaveAllResults2Files( page,whole_page_bin,whole_polygon_labels,merged_whole_blob_lines,fileName,dstPath);

    end

 end
toc
    function [new_polygon_labels]=make_new_labels(part_polygon_labels, max_label)
        new_polygon_labels=zeros(size(part_polygon_labels));
        part_labels=unique(part_polygon_labels);
        for i=2:length(part_labels)
            part_label=part_labels(i);
            new_polygon_labels(part_polygon_labels==part_label)=max_label+i;
        end
    end