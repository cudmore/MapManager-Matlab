% Author; Robert Cudmore
% Date: 20170927
%
% top todo:
%   (1) [done] load multiple maps
%   (2) [done] plot map based on session condition
%   (3) [done] pool multiple maps using session condition
%   (4) nearest-neighbor
%   (5) [done] segment auto-correlation
%   (6) [done] Append to map stats
%
% todo: function to plotSpine(session, spineIdx)
% todo: [done] write example to get stat and pDist, sort stat by pDist to get
%    spines in segment order
% todo: [done] example to plot session condition across maps

%% Introduction
% These are examples of how to use the Map Manager toolbox.
%
% The toolbox has three main classes:
%
%    mmMap : A Map Manager map
%    mmStack : A Map Manager stack
%    mmPlot : Utility class to plot maps and stacks
%
% Please see mmPlot for interactive plots that respond to mouse clicks.
help mmPlot

%% Getting help
% All classes and functions have help
help mmMap


%% Preliminaries

% Change into examples directory
cd('/Users/cudmore/Dropbox/MapManager-Matlab/examples');
addpath('..')

% Set default plot look and feel
set(0,'DefaultLineMarkerSize',7);
set(0,'defaultAxesFontSize',16);


%% Loading a map
%
% Load a map by specifying the full path to the map folder (not the Igor .ibw wave !)
mapPath = 'd:/Users/cudmore/MapManagerData/Richard/rr30a'; % Windows
mapPath = '/Users/cudmore/Dropbox/MapManagerData/richard/rr30a'; % Mac OS
myMap = mmMap(mapPath);


%% Using the default plot structure
%
% Throughout these examples we will use a structure to define parameters.
% Get the default plot structure using mmMap.defaultPlotStruct(). Most
% functions take ps as as paremter and return the same ps with new fields
% filled in.
%
% See: help mmMap.defaultPlotStruct
help mmMap.defaultPlotStruct

%% Example 1, plotting one stat versus session number
%
% See: mmPlot.plotStat()

ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum'; % background subtracted spine sume
ps.channel = 2;
ps = myMap.GetMapValues(ps);

figure;
plot(ps.sessions,ps.val,'ok', ps.sessions',ps.val','-k');
xlabel('Session');
ylabel('ubssSum');

% or
% mmPlot.plotStat(myMap, ps);


%% Example 1.1, plotting one stat versus days
%
% See: mmPlot.plotStat()

ps = mmMap.defaultPlotStruct();
ps.stat = 'ubsdSum'; %background subtracted dendrite sum
ps.channel = 1;
ps.mapsegment = NaN; % set to NaN for all
ps = myMap.GetMapValues(ps);

figure;
plot(ps.days,ps.val,'ok', ps.days',ps.val','-k');
xlabel('Days');
ylabel([ps.stat ' ch' num2str(ps.channel)]);

% or
% mmPlot.plotStat(myMap, ps, 'xAxis', 'days');
help mmPlot.plotStat

%% Example 1.2, one stat versus days as percent change of session 3
%
% See: mmPlot.mapPlotNorm()
ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum';
ps.channel = 2;
ps.mapsegment = nan; % set to NaN for all
ps = myMap.GetMapValues(ps);

normSession = 3;
percentChange = bsxfun(@rdivide, ps.val, ps.val(:,normSession)) * 100;
%absoluteChange = bsxfun(@subtract, ps.val, ps.val(:,normSession));

figure;
plot(ps.days, percentChange, 'ok', ps.days',percentChange','-k');
xlabel('Days');
ylabel(['% Change ' ps.stat ' ch' num2str(ps.channel)]);

% or
% mmPlot.plotStat(myMap, ps, 'Norm', '%', 'NormSession', normSession);


%% Example 1.3, get the mean/sd/se/n for each session

ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum';
ps.channel = 2;
ps.mapsegment = NaN; % set to NaN for all
ps = myMap.GetMapValues(ps);

the_mean = mean(ps.val,'omitnan');
the_std = std(ps.val,'omitnan');
the_count = sum(~isnan(ps.val));
the_se = the_std ./ sqrt(the_count-1);

% cludge to get days
the_days = mean(ps.days, 'omitnan');

% plot
grayLevel = 0.7;
figure;
plot(ps.days, ps.val, 'o', 'Color', [grayLevel,grayLevel,grayLevel]); % markers
hold on;
plot(ps.days',ps.val','-', 'Color', [grayLevel,grayLevel,grayLevel]); % lines
eh = errorbar(the_days,the_mean, the_se); % mean +/- standard error
eh.MarkerFaceColor = 'b';
eh.LineWidth = 3;
hold off;
xlabel('Days');
ylabel(ps.stat);


%% Example 1.4, Check if a stat name is a valid stat
myStat = 'ubssSum';
isValid = myMap.isValidStat(myStat);
if isValid
    disp([myStat ' is a valid stat']);
else
    disp([myStat ' is NOT a valid stat']);
end

myStat = 'badstat';
isValid = myMap.isValidStat(myStat);
if isValid
    disp([myStat ' is a valid stat']);
else
    disp([myStat ' is NOT a valid stat']);
end

% get names of all valid stats
%[validstats, ignor] = myMap.getValidStats();


%% Example 2, Plot 2 stats from 2 different channels
xps = mmMap.defaultPlotStruct();
xps.mapsegmentid = NaN; % set to NaN for all

xps.stat = 'ubssSum'; % background subtracted spine sum
xps.channel = 2;
xps = myMap.GetMapValues(xps);

yps = xps; % make sure they match (e.g. mapsegmentid)
yps.stat = 'ubsdSum'; % background subtracted dendrite sum
yps.channel = 1;
yps = myMap.GetMapValues(yps);

figure;
plot(xps.val, yps.val,'ok');
xlabel([xps.stat ' ch' num2str(xps.channel)]);
ylabel([yps.stat ' ch' num2str(yps.channel)]);

% or
% mmPlot.plotStat2(myMap, xps, yps);

%% Example 2.1, Overlay map segment 2 in red
%
% This is useful to see the distribution of one segment in the context
%   of all other segments
xps.mapsegment = 2;
xps = myMap.GetMapValues(xps);
yps.mapsegment = 2;
yps = myMap.GetMapValues(yps);

hold on;
plot(xps.val, yps.val, 'or', 'MarkerFaceColor', 'r');
hold off;


%% Example 2.3, plot a single stat for two different sessions
%
% See: mmPlot.mapPlotSession()
% This is useful to see how stats evolve over time
%   and can be used to examine percent or absolute change
ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum';
ps.channel = 2;
ps = myMap.GetMapValues(ps); % ps.val has ps.stat for all sessions

xSession = 2;
ySession = 5;
plot(ps.val(:,xSession), ps.val(:,ySession), 'ok');
xlabel([ps.stat ' session ' num2str(xSession)]);
ylabel([ps.stat ' session ' num2str(ySession)]);

% or
if 0
    xps = mmMap.defaultPlotStruct();
    xps.stat = 'ubssSum';
    xps.channel = 2;
    xps.session = 2;
    
    yps = mmMap.defaultPlotStruct();
    yps.stat = 'ubssSum';
    yps.channel = 2;
    yps.session = 5;
    
    mmPlot.plotStat2(myMap, xps, yps);
end

% Homework: Fit a line to this session plot to see if the stat changes between sessions.


%% Example 3, Plotting a cannonical Map Manager map of spine position along tracing.
ps = mmMap.defaultPlotStruct();
ps.mapsegment = 1;
mmPlot.plot0(myMap, ps)

%% Example 3.1, Plot added (green), subtracted (red), and transient (blue)
%

ps = mmMap.defaultPlotStruct();
ps.stat = 'pDist'; %'ubssSum';
ps.mapsegment = 1; % set to NaN for all

% get map dynamics
ps = myMap.GetMapDynamics(ps);

% get a map stat
ps = myMap.GetMapValues(ps);

% massage some things
[m,n] = size(ps.val); % GetMapValues() and GetMapDynamics() return the same size
yAdd = nan(m,n);
xAdd = nan(m,n);
yAdd(ps.added==1) = ps.val(ps.added==1);
xAdd(ps.added==1) = ps.sessions(ps.added==1); % coud use ps.sessions and markers will not show up because they are stripped out by yAdd
ySub = nan(m,n);
xSub = nan(m,n);
ySub(ps.subtracted==1) = ps.val(ps.subtracted==1);
xSub(ps.subtracted==1) = ps.sessions(ps.subtracted==1);
yTransient = nan(m,n);
xTransient = nan(m,n);
yTransient(ps.transient==1) = ps.val(ps.transient==1);
xTransient(ps.transient==1) = ps.sessions(ps.transient==1);

% plot
plot(ps.sessions, ps.val, 'ok', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
hold on;
plot(ps.sessions', ps.val', '-k');
hold on;
plot(xAdd, yAdd, 'og', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
plot(xSub,ySub,'or', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
plot(xTransient,yTransient,'ob', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
hold off;
xlabel('Session')
ylabel('Segment Position (\mum)');

% or
% todo: need to add dynamics colors to mmPlot


%% Example 4, Pooling a stat across a number of maps
%
% See /examples/poolingmaps.m
%

% poolingmaps.m is a script to pool across a number of maps.
% It uses session conditions {'c*', 'c2', 'e*'}
poolingmaps


%% Example 4.1, Pooling across maps is generalized in dopool.m
%
help dopool


%% Example 5, Generate segment statistics for all segments in a map

% See segmentStats.m for a template function to write your own segment analysis
ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum';
ps.channel = 2;
% The segmentanalysis() function will call segmentstats.m for each segment
% in the map.
%
% In this case there are 45 segments!
mySegmentStats = myMap.segmentanalysis(ps, 'segmentStats');

% plot results
for i = 1:myMap.numMapSegments
    eh = errorbar([mySegmentStats(i,:).mean], [mySegmentStats(i,:).se], 'o-'); % mean +/- standard error
    eh.LineWidth = 3;
    eh.DisplayName = ['Map Segment ' num2str(i)];
    hold on;
end

xlabel('Session')
ylabel(['Segment Mean of ' myStat]);
legend('show');
hold off;

%% Example 5.1, calculate autocorrelation for each segment for a single stat
%
% This is simple, we make a new matlab function (in a .m file) following
%   the prototype of segmentStats() in segmentStats.m.
% In this function we (1) sort val using pDist and (2) use autocorr
%   function at lag 0 (Requires the Econometrics toolbox)


%% Example 6, Plot dendritic tracings
% todo: rewrite mmStack.getTracing() to take ps and return ps.tracing

% look at first 5 rows in linedb table
myMap.stacks(1).linedb(1:5,:)

% In this example we are calling getTracing(). A member function of mmStack (not mmMap).
% Each mmMap has a list of mmStack in myMap.stacks
stackSegment = NaN; %NaN for all
session = 1;
tracing = myMap.stacks(session).getTracing(stackSegment);

plot(tracing(:,1), tracing(:,2), '.k', 'MarkerSize', 25);
xlabel('\mum');
ylabel('\mum');

% Have a look at the help
help mmStack.getTracing

%% Example 7, Display maximal intensity projection with annotations and tracing
%
% See: mmPlot.mapPlotImage()
mySession = 1;
myChannel = 2;
myMap.plotMaxProject(mySession, myChannel);

% or
% plotMaxProject(myMap,ps,showAnnotations, showLines);


%% Example 8, Find notes, errors, and warnings in a map
result1 = myMap.find('note', 'Dim?');
disp(result1(1:5,:)) % view table of first 5 results

% Other examples
% result2 = myMap.find('note', '*');
% result2(1:5,:)
% result2 = myMap.find('error', '*');
% result2(1:5,:)
% result3 = myMap.find('warning', '*');
% result3(1:5,:)


%% Example 9, Add new analysis to a map
ps = mmMap.defaultPlotStruct();
ps.stat = 'ubssSum'; %'ubssSum';
ps.channel  = 2;
ps = myMap.GetMapValues(ps);
newStatName = 'myNewStat';
[m,n] = size(ps.val);
newStatValues = NaN(m,n);
newStatValues = ps.val ./ mean(ps.val(~isnan(ps.val))); % ubssSum / mean(ubssSum);

newStatName = 'myNewStat';
newStatValues = ps.val;

myMap.addUserStat(ps, newStatName, newStatValues);

% and then plot the new stat
ps = myMap.GetMapValues(ps);
ps.stat = newStatName;
myMap.plotStat(ps);

% or use mmPlot class directly, the plots are clickable
% mmPlot.plotStat(myMap, ps);

% and then save
myMap.save();

% now, load the map again and you will have your new stat


