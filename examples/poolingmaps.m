% Example to pool a stat across a number of maps
% Taking the mean for each spine across conditions in the map

% Author: RObert Cudmore
% Date: 20171016

addpath('..')

%% Load a number of maps
folderPath = '/Users/cudmore/Dropbox/MapManagerData/richard';
files = dir(folderPath);
subFolders = files([files.isdir]);
numFolders = length(subFolders);
numMaps = 0;
for i = 1:numFolders
    folderName = subFolders(i).name;
    if strcmp(folderName,'.') || strcmp(folderName,'..')
        continue
    end
    mapPath = [folderPath '/' folderName];
    numMaps = numMaps + 1;
    disp(['Loading map ' num2str(numMaps) ' of ' num2str(numFolders-2) ' ' mapPath]);
    myMapList(numMaps) = mmMap(mapPath);
end

%% print out session conditions for each map
%for i = 1:numMaps
%    disp([num2str(i) ' ' myMapList(i).mapName ' has session conditions']);
%    disp(myMapList(i).mapNV('condStr',:));
%end

%% set condStr manually
myMapList(1).mapNV('condStr',1) = {'c1'};
myMapList(1).mapNV('condStr',2) = {''};
myMapList(1).mapNV('condStr',3) = {'c2'};
myMapList(1).mapNV('condStr',4) = {''};
myMapList(1).mapNV('condStr',5) = {'c3'};
myMapList(1).mapNV('condStr',6) = {'e1'};
myMapList(1).mapNV('condStr',7) = {''};
myMapList(1).mapNV('condStr',8) = {'e2'};

myMapList(2).mapNV('condStr',2) = {'c1'};
myMapList(2).mapNV('condStr',3) = {'c2'};
myMapList(2).mapNV('condStr',5) = {'e1'};
myMapList(2).mapNV('condStr',6) = {'e2'};

%% put together a map pool based on a list of session conditions, myCondList
myCondList = {'c*', 'c2', 'e*'};
myStat = 'ubssSum';
myChannel = 2;
myPool = doPool(myMapList, myStat, myChannel, myCondList)

%% plot results
figure;
% markers
plot(myPool.poolCondNum, myPool.poolVal, 'ok');
% lines
hold on;
plot(myPool.poolCondNum', myPool.poolVal', '-k');
hold off;
xlabel('Conditions');
xticks(myPool.poolCondNum(1,:)); % find a better way of doing this
xticklabels(myCondList)
ylabel(myStat);
        
