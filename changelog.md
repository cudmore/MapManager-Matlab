## Change log for MapManager-Matlab

## [v1.0.1-alpha] - 2017-10-16

- Initial release.
- Seeded to R Roth.

## v1.0.1-alpha2 - In Preparation

### Major
- All plot function reduce plot struct (ps) matrices by stripping NaN rows. This speeds up code and makes looking at things like ps.val much easier.

### Minor
- Expanded help
- mmPlot plots for ps.session now show session on x/y axis

### To Do
- Standardize case for class methods, e.g. mmMap.GetMapValues() to mmMap.getMapValues().
- Figure out why loading .tif files is so slow.


[v1.0.1-alpha]: https://github.com/cudmore/MapManager-Matlab/releases/tag/v1.0.1-alpha