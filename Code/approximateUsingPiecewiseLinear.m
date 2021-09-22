function [ LineIndices ] = approximateUsingPiecewiseLinear( L,num, marked, ths )

 res = regionprops(L,'PixelList','Area');
 
 %better version
 %numOfKnots =20;
 
 %conference version
 numOfKnots = 20;
 
 fitting_average_of_distances = zeros(num,numOfKnots-1);
 %fitting_difference_of_areas = zeros(num,1);

 %figure; imshow(L); hold on;

for i=1:num
    if (ismember(i,marked))
        fitting_average_of_distances(i,:) = 0;
        %fitting_difference_of_areas(i) = 1;
        continue;
    end    
    pixelList = res(i,1).PixelList;
    x = pixelList(:,1);
    y = pixelList(:,2);
    
    % For speed up, we first try to fit a straight line, if the results are
    % really poor. We don't continue.
    p = polyfit(x,y,1);
    y_hat = polyval(p,x);
    fit = norm(y_hat - y,1)/length(x);
    if (fit > ths)
        fitting_average_of_distances(i,:) = fit;
        %fitting_difference_of_areas(i) = 0;
        continue;
    end
    
    %conference version include this:
    %difference of the blob area and the sum of the distances of the
    %boundary pixels to the spline.
    %Berat begin
%     [boundary_x,~,idx]  = unique(x);
%     boundary_y = accumarray(idx,y,[],@max); 
%     boundary_y_hat = polyval(p,boundary_x);
%     apprx_area = 2*norm(boundary_y_hat - boundary_y,1);
%     blob_area=length(x);
%     fit_area=min(apprx_area,blob_area)./max(apprx_area,blob_area);
%     fitting_difference_of_areas(i)=fit_area;
    %Berat end
    
    try
        slm = slmengine(x,y,'degree',1,'knots',numOfKnots,'plot','off');
    catch
        fprintf('problem in CC %d\n',i);
        continue;
    end
    for j=1:numOfKnots-1
       x_endP = slm.knots(j:j+1);
       y_endP = slm.coef(j:j+1);
       p = polyfit(x_endP,y_endP,1);     
       indices = find(x >= x_endP(1) & x <= x_endP(2));
       x_ = x(indices);
       y_ = y(indices);
       y_hat = polyval(p,x_);
       
       %plot(x_,y_hat,'LineWidth',5);

       fitting_average_of_distances(i,j) = norm(y_hat - y_,1)./length(x_);     
       
    end
end
fitting_average_of_distances= max(fitting_average_of_distances,[],2);

%conference version: compare only to max_scale
%conference version:  1. The average distance of component pixels from the spline. 
%2. The difference of component area and the sum of distances of contour pixels 
%from the spline
%LineIndices = find(fitting_average_of_distances < ths & fitting_difference_of_areas>0.8);

%better version: compare to 0.8*max_scale
%better version:  1. The average distance of component pixels from the spline.
%better version to compare to  0.8*max_scale instead of max_scale
%LineIndices = find(fitting_average_of_distances < 0.8*ths );
LineIndices = find(fitting_average_of_distances < 0.8*ths );

end
