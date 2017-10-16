% Example protoype function to be passed to mmMAp.segmentAnalysis()
%   Write your own and return
%   retVal : A single number for each segment
%       Can be a struct as in this example
%   retVec : 
%
% Example Usage:
%   myPath = '/path/to/map/manager/map/folder';
%   myMap = mmMap(myPath);
%
%   myFunction = 'segmentStats'; % in this example there needs to be a .m file segmentStats.m 
%   myStat = 'ubssSum'
%   myChannel = 2;
%   mySegmentStats = myMap.segmentanalysis(myMap, myStat, myChannel, myFunction)
%
% mySegmentStats is (myMap.numSegments,myMap.numSessions) matrix
% where mySegmentStats(i,j) is retVal returned from @segmentStats
%
% In this example, retVal is a struct containing statistics for 'ubssSum'
%   for each segment.

% Author: Robert Cudmore
% Date: 20171008

% Function prototype to be passed to mmMap.segmentAnalysis f
function [retVal,retVec] = segmentStats(theMap, theSession, theMapSegment, theVals, the_pDist)
    
    retVal.mean = mean(theVals(~isnan(theVals)));
    retVal.std = std(theVals(~isnan(theVals)));
    retVal.count = sum(~isnan(theVals));
    retVal.se = retVal.std / sqrt(retVal.count-1);
    
    retVec = NaN;

    dispStr = ['   segmentStats() for map:' theMap.mapName ' session:' num2str(theSession) ' mapsegment:' num2str(theMapSegment)];
    dispStr = [dispStr ' mean:' num2str(retVal.mean) ' std:' num2str(retVal.std) ' count:' num2str(retVal.count)];
    %disp(dispStr);
end

