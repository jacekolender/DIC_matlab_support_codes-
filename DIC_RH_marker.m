clearvars -except handles_ncorr;
sourcefolder = 'your_folder_here';
cd(sourcefolder)
DIC_images_list = natsortfiles(dir(fullfile(sourcefolder, '*DIC_*.tif'))); %find the files where RH and temp data are saved. There have to be more than two (this should be redesigned at some point)
DIC_file = dir(fullfile(sourcefolder, '*full_data*.xlsx')); 
DIC_name = DIC_file.name;
DIC_data = readtable(DIC_name);
%% run section
n = numel(DIC_images_list);
image_matrix = zeros(n,2);
all_labels = {};
all_datetime = datetime();
for k = 1:n
    image_file = DIC_images_list(k).name;
    image_file = string(image_file);
    image_number = erase(image_file,'DIC_Image_');
    image_number = erase(image_number,'.tif');
    image_number = str2double(image_number);
    [~,image_idx] = ismember(image_number,DIC_data.DIC_image_);
    image_time = datetime(DIC_data{image_idx,1});
    all_datetime(k,1) = image_time;
    image_matrix(k,1) = DIC_data{image_idx,5};
    image_matrix(k,2) = image_number;
    image_time = string(image_time);
    image_RH = string(DIC_data{image_idx,5});
    image_RH = append(image_RH,'%');
    photo_number = string(k-1);
    photo_number = append('img ',photo_number,' - ');
    image_number = string(image_number);
    image_number = append(photo_number,image_number);
    %label = append(image_number,', ',image_time,', ',image_RH);
    label = [image_number;image_time;image_RH];
    all_labels{end+1} = label;
end

figure
scatter(DIC_data.Time, DIC_data.MainRH,25,'Marker','.','MarkerFaceColor','b','MarkerEdgeColor','b')
hold on
scatter(all_datetime,image_matrix(:,1),30,'Marker','o','MarkerEdgeColor','r')
text(all_datetime,image_matrix(:,1),all_labels,'VerticalAlignment','top','HorizontalAlignment','right')
%% 
all_datetime = all_datetime';
image_matrix = array2table(image_matrix);
all_datetime = array2table(all_datetime');
all_table = [all_datetime image_matrix];
all_table.Properties.VariableNames = [{'Time'},{'RH'},{'Image nr'}];
writetable(all_table,"images_positions_partial.xlsx","FileType",'spreadsheet');
