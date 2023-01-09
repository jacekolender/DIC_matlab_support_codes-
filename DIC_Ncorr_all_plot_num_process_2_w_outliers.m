%code for extracting the data from ncorr DIC analysis. requires starting
%ncorr as "handles_ncorr = ncorr"
%% run section
clearvars -except handles_ncorr;
sourcefolder = 'C:\Users\jo62n\OneDrive - University of Glasgow\Temp\DIC_2022_10_19\Selected Entire Run'; %change folder accordingly to the DIC analysis folder
cd(sourcefolder);
exx_strains = struct('plot_exx_ref_formatted', {handles_ncorr.data_dic.strains(1:end).plot_exx_ref_formatted});
eyy_strains = struct('plot_eyy_ref_formatted', {handles_ncorr.data_dic.strains(1:end).plot_eyy_ref_formatted});
n = numel(exx_strains);
all_matrix = zeros(n,19);
%add consecutive file numbers matching these in ncorr
all_matrix(:,1) = 1:1:n;
DIC_file = dir(fullfile(sourcefolder, '*full_data*.xlsx')); 
DIC_data = readtable(DIC_file.name);

for k = 1:n
%extract plot data
exx_plot = exx_strains(k).plot_exx_ref_formatted; 
eyy_plot = eyy_strains(k).plot_eyy_ref_formatted;

%remove the non-ROI data points - works only with rectangular ROIs - other
%ROIs will still include 0-points, just fewer of them
exx_plot_clean = exx_plot(any(exx_plot,2),any(exx_plot,1));
eyy_plot_clean = eyy_plot(any(eyy_plot,2),any(eyy_plot,1));

exx_plot_clean_pos = exx_plot_clean(exx_plot_clean > 0);
exx_plot_clean_neg = exx_plot_clean(exx_plot_clean < 0);

eyy_plot_clean_pos = eyy_plot_clean(eyy_plot_clean > 0);
eyy_plot_clean_neg = eyy_plot_clean(eyy_plot_clean < 0);

%Mean and std deviation overall
exx_std_dev = std(exx_plot_clean,0,'all');
eyy_std_dev = std(eyy_plot_clean,0,'all');

%mean and std dev positive and negative directions
exx_std_dev_pos = std(exx_plot_clean_pos,0,'all');
exx_std_dev_neg = std(exx_plot_clean_neg,0,'all');
eyy_std_dev_pos = std(eyy_plot_clean_pos,0,'all');
eyy_std_dev_neg = std(eyy_plot_clean_neg,0,'all');

%Minima, maxima and range calculated and added to the table
all_matrix(k,3) = min(exx_plot_clean,[],'all');
all_matrix(k,4) = max(exx_plot_clean,[],'all');
all_matrix(k,5) = all_matrix(k,4) + abs(all_matrix(k,3));
all_matrix(k,6) = mean(exx_plot_clean,'all');
%all_matrix(k,7) = exx_std_dev; %alternative version, depepending on which
%std dev values are preferred
all_matrix(k,7) = exx_std_dev_pos;
all_matrix(k,8) = exx_std_dev_neg;
all_matrix(k,9) = mean(exx_plot_clean_pos);
all_matrix(k,10) = mean(exx_plot_clean_neg);
all_matrix(k,11) = min(eyy_plot_clean,[],'all');
all_matrix(k,12) = max(eyy_plot_clean,[],'all');
all_matrix(k,13) = all_matrix(k,11) + abs(all_matrix(k,12));
all_matrix(k,14) = mean(eyy_plot_clean,'all');
%all_matrix(k,15)= eyy_std_dev; %as above
all_matrix(k,15) = eyy_std_dev_pos;
all_matrix(k,16) = eyy_std_dev_neg;
all_matrix(k,17) = mean(eyy_plot_clean_pos);
all_matrix(k,18) = mean(eyy_plot_clean_neg);


%save original photo file number in the final file
photo_file = handles_ncorr.current(k).imginfo.name;
photo_file = string(photo_file);
photo_file = erase(photo_file,'DIC_Image_');
photo_file = erase(photo_file,'.tif');
all_matrix(k,2) = double(photo_file);
end
%% run section
%get the timestamps and RH values
image_time = datetime();
for v = 1:n
    img_no = all_matrix(v,2);
    [~,image_idx] = ismember(img_no,DIC_data.DIC_image_);
    if image_idx == 0
        v = v+1;
    else
        image_time(v) = datetime(DIC_data{image_idx,1});
        all_matrix(v,19) = string(DIC_data{image_idx,5});

    end
end

%% run section
labels = {'Photo number (ncorr)','Photo label (original file)','Exx Min','Exx Max','Exx Range','Exx Mean (all)','Exx Std dev+','Exx Std dev-','Exx Mean +','Exx Mean -','Eyy Min','Eyy Max','Eyy Range','Eyy Mean (all)','Eyy Std dev+','Eyy Std dev-','Eyy Mean +','Eyy Mean -','RH','Timestamp'};
%all_matrix = [exx_min,exx_max,exx_range,exx_mean,exx_std_dev;eyy_min,eyy_max,eyy_range,eyy_mean,eyy_std_dev];
all_table = array2table(all_matrix);
image_time = image_time';
image_time = array2table(image_time);
all_table = [all_table image_time];
all_table.Properties.VariableNames = labels;
writetable(all_table,"single_frame_analysis_all_graphs_w_outliers.xlsx","FileType",'spreadsheet');

