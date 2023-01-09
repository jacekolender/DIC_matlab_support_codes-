sourcefolder = 'C:\Users\jo62n\OneDrive - University of Glasgow\Temp\DIC_2022_10_19'; %change folder as appropriate
addpath(sourcefolder);
cd(sourcefolder)
DIC_images_list = natsortfiles(dir(fullfile(sourcefolder, '*DIC_Image_*.tif')));
files_list = struct2table(DIC_images_list);
timestamps = datetime();
for n = 1:length(files_list.name)
    img_file = files_list.name(n);
    info = imfinfo(img_file{1,1});
    timestamps(1,n) = info.FileModDate;
end
timestamps_tab = array2table(timestamps);
writetable(timestamps_tab,"img_timestamps.xlsx","FileType",'spreadsheet');
