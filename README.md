# behavior_medpc

**Behavioral analysis tools for MedPC files**  
*MATLAB & (eventually) Python utilities for rodent behavior analysis from Med Associates chambers*

For researchers analyzing **operant conditioning**, **Pavlovian tasks**, **reinforcement schedules**, or any **MedPC behavioral experiment**.

[![MATLAB](https://img.shields.io/badge/MATLAB-%23E6194B.svg?&style=for-the-badge&logo=MATLAB&logoColor=white)](https://www.mathworks.com)

## Features

- Read raw MedPC output files into MATLAB and Python structures.
- Parse sessions and extract trial-by-trial data.
- Basic utilities to clean and organize MedPC data for further analysis.

*(Note: This project is under active development and the API may change.)*

## Requirements

| Dependency | Version | Link |
|---|---|---|
| MATLAB | R2020a+ | https://www.mathworks.com |
| matlab-utilities | `main` (untagged) | https://github.com/Willuhn-Group/matlab-utilities |

`matlab-utilities` provides `getEntry`, `wfig` and `avg_err_shade`, which
`getTrials`, `eventHistogram` and the example script call.

## Installation

1. Clone this repository and [utilities_matlab](https://github.com/Willuhn-Group/utilities_matlab).
2. Add both to the MATLAB path:
   ```matlab
   addpath(genpath('<path to>/medpc-behavior/matlab'));
   addpath(genpath('<path to>/matlab-utilities'));
   ```
3. Run `example_use/multipelletExample.m` to check the setup. It stops with a
   clear message if matlab-utilities is missing.

## Repository structure

matlab/   	% MATLAB functions to read and parse MedPC files
example_use/ 	% Example MATLAB scripts using the functions in matlab/
example_data/ 	% Some MedPC files used in the examples in example_use/

Python versions planned.
