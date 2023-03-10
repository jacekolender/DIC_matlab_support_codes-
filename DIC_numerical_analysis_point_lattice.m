%code for extracting the data from ncorr (c Justin Blaber) DIC analysis and extracting strain data from a regular 5x5 point lattice (25 points altogether). It allows to trace changes in strain over all images in a given DIC analysis. It requires starting
%ncorr as "handles_ncorr = ncorr". Obviously it requires conducting the DIC analysis first.
%% run section
%find data
clearvars -except handles_ncorr;
sourcefolder = 'your_folder_here'; %change folder accordingly to the DIC analysis folder
cd(sourcefolder);
exx_strains = struct('plot_exx_ref_formatted', {handles_ncorr.data_dic.strains(1:end).plot_exx_ref_formatted});
eyy_strains = struct('plot_eyy_ref_formatted', {handles_ncorr.data_dic.strains(1:end).plot_eyy_ref_formatted});
n = numel(exx_strains);
DIC_file = dir(fullfile(sourcefolder, '*full_data*.xlsx')); 
DIC_data = readtable(DIC_file.name);

%calculate the size of the ROI and calculate the positions of the point lattice
x_width = handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.rightbound - handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.leftbound;
y_height = handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.lowerbound - handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.upperbound;

%with 5x5 lattice, the position of points is spaced at every 20% of given dimension of the ROI matrix
x_by_5 = floor(x_width / 5);
y_by_5 = floor(y_height / 5);
%lattice it positioned at 12.5% of a given dimension of the matrix
start_point_x = ceil(x_by_5/2);
start_point_y = ceil(y_by_5/2);
%create x and y vectors
x_vector = start_point_x:x_by_5:x_width;
y_vector = start_point_y:y_by_5:y_height;

x_vector = x_vector';
y_vector = y_vector';
%mesh vectors into the lattice grid
[idx,idy] = ndgrid(1:numel(x_vector),1:numel(y_vector));
grid = [y_vector(idy(:)),x_vector(idx(:))];

%% run section
%preallocate space for data points
exx_matrix = zeros(n,numel(grid(:,1))+2);
exx_matrix(:,1) = 1:1:n;
eyy_matrix = zeros(n,numel(grid(:,1))+1);
eyy_matrix(:,1) = 1:1:n;

image_time = datetime();

for k = 1:n
%extract plot data
exx_plot = exx_strains(k).plot_exx_ref_formatted; 
eyy_plot = eyy_strains(k).plot_eyy_ref_formatted;

%remove the non-ROI data points. This works perfectly only with rectangular ROIs, as it only creates a box around the furthest non-zero data points in the analysed images. Irregular ROIs will still include 0-value points, just fewer of them.
exx_plot_clean = exx_plot([handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.upperbound:handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.lowerbound],[handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.leftbound:handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.rightbound]);
eyy_plot_clean = exx_plot([handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.upperbound:handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.lowerbound],[handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.leftbound:handles_ncorr.data_dic.strains(1).roi_ref_formatted.region.rightbound]);

%Data extraction loop. It goes through each image, then internal loop iterates through the lattice data points
for j = 1 : numel(grid(:,1))
    exx_matrix(k,j+3) = exx_plot_clean(grid(j,1),grid(j,2));
    eyy_matrix(k,j+1) = eyy_plot_clean(grid(j,1),grid(j,2));
end
    %extract photo numbers
    photo_file = handles_ncorr.current(k).imginfo.name;
    photo_file = string(photo_file);
    photo_file = erase(photo_file,'DIC_Image_');
    photo_file = erase(photo_file,'.tif');
    exx_matrix(k,2) = double(photo_file);

    %get the timestamps and RH values
end
    for v = 1:n
    img_no = exx_matrix(v,2);
    [~,image_idx] = ismember(img_no,DIC_data.DIC_image_);
    image_time(v) = datetime(DIC_data{image_idx,1});
    exx_matrix(v,3) = DIC_data{image_idx,5};
    end

all_matrix = horzcat(exx_matrix,eyy_matrix);

%% image section
img = rescale(exx_plot_clean);

figure 
imshow(img)
hold on
for c = 1:length(grid(:,1))
    label = num2cell(c);
    plot(grid(c,2),grid(c,1), 'r+', 'MarkerSize', 6, 'LineWidth', 3);
    text(grid(c,2)+5,grid(c,1)+5,label);
end
rectangle('Position',[1,1,width(img)-1,length(img)-1],'LineWidth',3)
hold off

%% run section
%compile data and save data
all_table = array2table(all_matrix);
image_time = image_time';
image_time = array2table(image_time);
all_table = [image_time all_table];
writetable(all_table,"single_frame_analysis_point_lattice.xlsx","FileType",'spreadsheet');

