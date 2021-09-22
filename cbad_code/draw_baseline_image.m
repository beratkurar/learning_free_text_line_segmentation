function draw_baseline_image(all_baseline_indices,original_image,draw_save_path)

[rows,cols,~] =size(original_image);
for i=1:length(all_baseline_indices)
    one_baseline_indices=all_baseline_indices{i};
    if isempty(one_baseline_indices)
        continue;
    end
    [row,col]=ind2sub([rows,cols],one_baseline_indices);
    original_image=insertMarker(original_image,[col,row]);
end
imwrite(original_image,draw_save_path);
end   
