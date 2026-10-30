# behavior_medpc

**Behavioral analysis tools for MedPC files**  
*MATLAB tools (Python planned) for rodent behavior analysis from Med Associates chambers*

For researchers analyzing **operant conditioning**, **Pavlovian tasks**, **reinforcement schedules**, or any **MedPC behavioral experiment**.

[![MATLAB](https://img.shields.io/badge/MATLAB-%23E6194B.svg?&style=for-the-badge&logo=MATLAB&logoColor=white)](https://www.mathworks.com)

## Features

- Read raw MedPC output files into MATLAB structures.
- Parse sessions into trial-by-trial data: trials, events, latencies, bouts.
- Event histograms and rasters across trials.

## Requirements

| Dependency | Version | Link |
|---|---|---|
| MATLAB | R2020a+ | https://www.mathworks.com |
| utilities_matlab | `main` (untagged) | https://github.com/Willuhn-Group/utilities_matlab |

`utilities_matlab` provides `getEntry`, `wfig` and `avgErrorShade`, which
`getTrials`, `eventHistogram` and the example script call.

## Installation

1. Clone this repository and [utilities_matlab](https://github.com/Willuhn-Group/utilities_matlab).
2. Add both to the MATLAB path:
   ```matlab
   addpath(genpath('<path to>/behavior_medpc/matlab'));
   addpath(genpath('<path to>/utilities_matlab'));
   ```
3. Run `example_use/multipelletExample.m` to check the setup. It stops with a
   clear message if utilities_matlab is missing.

## Usage

```matlab
cfg         = [];
cfg.medFile = fullfile('<path to>', 'my_medpc_file');
cfg.events  = ...;               % task-specific MedPC event codes
trialStruct = getTrials(cfg);
```

The event codes depend on your MedPC program. `example_use/multipelletExample.m`
walks through the full flow (`readMedpc` → `getTrials` → `addEvent` →
`extractBouts` / `eventHistogram`) for the multipellet task, using the file in
`example_data/`.

## Repository structure

```
matlab/        % functions to read and parse MedPC files
example_use/   % example scripts using the functions in matlab/
example_data/  % small MedPC files used by the examples
```

## Status

Under active development: the API may still change. No release yet; the first
tag will be `v0.1.0`. Project repos should pin a release once it exists.

## Citation

If you use this code, please cite the release you used (see *Releases*).

## License

MIT, see [LICENSE](LICENSE).

## Authors

Sergio Conde-Ocazionez (leader) · Neuromodulation & Behavior Group (Willuhn lab),
Netherlands Institute for Neuroscience
