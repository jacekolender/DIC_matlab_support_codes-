%The code analyses compiles RH data from the labview files and overlays the
%DIC photos timestamps over the RH data and load data. The code requires
%the preformatted file with the photos timestamps saved as
%'filenames_*.xlsx'. You can create it by going to the folder with all the
%files, highlighting all the files and right-clicking on the first file
%while holding SHIFT key. From the context menu choose 'Copy as path'.
%Open empty excel spreadhseet and paste the filepaths into A1 cell. Check
%if the file in the first line is the first one from the folder. Then using
%function 'replace' remove everything from the spreadsheet that is not
%date- and time stamp. Usually you will just need to remove everything from
%before the year and the .tif extensions.

clearvars -except handles_ncorr;
sourcefolder = 'your_folder_here'; %change folder as appropriate
addpath(sourcefolder);
cd(sourcefolder)
DIC_files_list = natsortfiles(dir(fullfile(sourcefolder, '*DIC_*.xlsx'))); %find the files where RH and temp data are saved. There have to be more than two (this should be redesigned at some point)
DIC_filenames = dir(fullfile(sourcefolder, 'filenames_*.xlsx')); %get the file where the photos timestamps are prepared


filenames = struct2table(DIC_filenames); %get the file names from the list
read_photo_file = filenames.name; %read the name
image_files = readtable(read_photo_file,'ReadVariableNames', false); %prevent skipping the first line
image_files = datetime(image_files.Var1,'InputFormat','yyyy_MM_dd_HHmmss.SSS'); %convert to datetime
%photos_rows = zeros(length(image_files),1); %reserve space for the photo timestamps indexes
photos_RH = zeros(length(image_files),1); %as above, but for the RH values
photos_time = zeros(length(image_files),1); %as above, but for the timestamps themselves
photos_load = zeros(length(image_files),1); %as above for load data
x = duration(35087,59,58); %labview-to-excel-to-matlab timestamp conversion, necessary additionn (check if it works out well comparing resulting variable with the original file)

dic_rh_full = zeros(1,6); %reserve space for the RH data from the sensors

files_list = struct2table(DIC_files_list); %get all the files containing RH and instron data
time_date_full = datetime(); %prepare datetime variable for the timestamps


for n = 1:length(DIC_files_list) %a for loop that combines the RH/temp/instron excel files from labview into one data set
    dic_rh_file = files_list.name(n); %get the name of the n-th file
    time_date_current = readtable(dic_rh_file{1}); %read the n-th file
    time_date_current.Properties.VariableNames = [{'Time'},{'Mixing RH'},{'Mixing Temp'},{'Main Temp'},{'Main RH'},{'Instron Load'},{'Instron Extension'}]; %rename the variables
    time_date_current = datetime(time_date_current.Time,'InputFormat','dd/MM/yyyy HH:mm:ss.SSS'); %read the timestamps in the correct format
    time_date_current = time_date_current+x; %add the time correction - datetime data when saved by labview into excel are coded in a specific way that confuses matlab when it reads them. This correction sets the makes the date right again  
    time_date_current(1) = []; %cut the sensor overload data point that appears every time labview is restarted
    time_date_current = dateshift(time_date_current, 'start', 'second', 'nearest'); %round up the datetime stamp to the nearest second
    time_date_full = [time_date_full;time_date_current]; %add the current timestamps to the rest
    current_rh_file = xlsread(dic_rh_file{1}); %read the rest of the data from the file
    current_rh_file(1,:) = []; %cut the first row again (as it was cut above)
    dic_rh_full = [dic_rh_full;current_rh_file]; %combine the rest of the RH/temp/instron data into one file
end
dic_rh_full(1,:) = []; %cut the first line of the prepared zeroes file
dic_rh_full(:,7) = 0; %prepare the RH file for the photo markers
time_date_full(1,:) = []; %cut the forst row of the zeros titmestamp variable

rh_data_freq = time_date_full(2) - time_date_full(1); %get the labview datalogging frequency

for  i = 1:length(image_files)
    photo_timestamp = image_files(i);
    timestamp_low = photo_timestamp - rh_data_freq;
    timestamp_high = photo_timestamp + rh_data_freq;
    tf = isbetween(time_date_full,timestamp_low,timestamp_high);
    [idx,~] = find(tf);
    for v = 1:numel(idx)
        idx_curr = idx(v);
        dt_diff(v,:) = abs(photo_timestamp - time_date_full(idx_curr));
    end
    [min_diff, idx_2] = min(dt_diff);
        if  isempty(idx)
            i = i+1;
        elseif numel(idx)<idx_2
            target_idx = idx(1);        
            photos_RH(i) = dic_rh_full(target_idx,4);
            photos_load(i) = dic_rh_full(target_idx,5);
            dic_rh_full(target_idx,7) = i-1;
            i = i+1;
        else
            target_idx = idx(idx_2);        
            photos_RH(i) = dic_rh_full(target_idx,4);
            photos_load(i) = dic_rh_full(target_idx,5);
            dic_rh_full(target_idx,7) = i-1;
            i = i+1;
        end
end

%convert files and save them
table1 = array2table(time_date_full);
table2 = array2table(dic_rh_full);
table2.dic_rh_full7(table2.dic_rh_full7==0) = NaN;
table_full = [table1 table2];
table_full.Properties.VariableNames = [{'Time'},{'Mixing RH'},{'Mixing Temp'},{'Main Temp'},{'Main RH'},{'Instron Load'},{'Instron Extension'},{'DIC_image?'}];
writetable(table_full,"DIC-full_data.xlsx","FileType",'spreadsheet');

%show plot of RH data with photos
scatter(time_date_full,dic_rh_full(:,4),25,'Marker','.','MarkerFaceColor','b','MarkerEdgeColor','b')
hold on
scatter(image_files,photos_RH,25,'Marker','.','MarkerFaceColor','r','MarkerEdgeColor','r')
hold off

figure %new figure

%show plot of load data with photos
scatter(time_date_full,dic_rh_full(:,5),25,'Marker','.','MarkerFaceColor','b','MarkerEdgeColor','b')
hold on
scatter(image_files,photos_load,25,'Marker','.','MarkerFaceColor','r','MarkerEdgeColor','r')
hold off
