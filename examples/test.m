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
% Please see mmPlot.plotStat() for interactive plots that respond to mouse clicks.


%% Using the default plot structure
%
% Throughout these examples we will use a structure to define parameters.
%
% Get the default plot structure using mmMap.defaultPlotStruct().
%
% See: help mmMap.defaultPlotStruct()

ps = mmMap.defaultPlotStruct()


%% Example 1, plotting one stat versus session number
%
% see: mmPlot.plotStat(ps)

%% Example 8, Plot a stat versus session using session condition
%
% see: mmPlot.mapPlotCondition()
%
%Each session in a map has a session condition
%myMap.mapNV('condStr',:)
%mp = mmPlot(myMap);
%h = mp.mapPlotCondition('ubssSum', 2, {'a1', 'b1', 'c2'});

% You can easily set session conditions yourself
%myMap.mapNV('cond',[1 2 3 4]) = ['c1', 'c2','e1','e2']
