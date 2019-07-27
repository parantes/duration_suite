# duration_suite.praat

A script for duration extraction.

## Purpose

Takes one or multiple segmented TextGrid files and extracts duration values in milliseconds for non-empty intervals in a user-specified interval tier. The script also offers the following three transformations to the raw duration contour. The user chooses which ones are applied:

1. Normalize raw duration contour by a z-score transformation;
2. Smooth the contour by applying one of two moving average techniques;
3. Find peaks in duration contour.

## Input
Previously segmented TextGrid files.
 
## Output
A report in tabular format listing duration for each labelled interval in the input TextGrid files.

## Parameters

Upon running the script, a window like the one below will appear, where the user has to set a number of parameters.

![Script GUI](figs/script-gui.png)

The parameters are:

- **Mode**: script runs on either a single file or on all TextGrid files on a user-specified folder;
- **Folder**: in case "Multiple files" option is selected, this is the folder where the script will look for TextGrid files;
- **Tier**: interval tier where ;
- **Language**: if user wants duration to be normalized, a language has to be selected (Brazilian Portuguese only at the moment);
- **Smoothing method**: choice of smoothing technique;
- **Alpha**: smoothing constant (used in case exponential smoothing is selected);
- **Information in the report**: raw duration is always logged on the report; normalized duration, smoothed duration and stress group boundary can be enabled individually;
- **Report**: report file path, name and extension. 

## Changelog

See the [CHANGELOG](CHANGELOG.md) file for the complete version history.

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations.

<!--
## Comments
Script file and user files don't need to be in the same file directory.

## How to cite

Click on the DOI badge above to see instructions on how to cite the script.

## Reference
-->

