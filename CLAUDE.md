# CLAUDE.md — behavior_medpc

@../.github/LAB_CONVENTIONS.md

> If the import above did not load (the `.github` repo is not cloned next to this
> one), read https://github.com/Willuhn-Group/.github/blob/main/LAB_CONVENTIONS.md
> before changing anything. Those rules apply here.

## What this repo is
- **Type:** general-purpose (used by project repos, e.g. `analysis_ephys_SIP`)
- **Purpose:** read MedPC (Med Associates) output files and turn them into
  trial-by-trial behavioral data: trials, events, latencies, bouts, histograms.
- **Leader:** Sergio Conde-Ocazionez (reviews every PR into main)
- **Current version:** untagged (first tag planned: v0.1.0)

## Layout
```
matlab/
  readMedpc.m        % raw MedPC file -> struct
  getTrials.m        % trial/ITI structure from event codes (cfg.events)
  addEvent.m         % add event times, latencies, first events, bouts per trial
  extractBouts.m     % group timestamps into bouts (minInterval, minDuration)
  eventHistogram.m   % event histograms across trials
  eventRaster.m      % raster of event times, one row per trial
  medEvents.m        % event extraction helper
example_use/
  multipelletExample.m   % full walkthrough on example_data/example_rat_multipellet
example_data/
```

## Typical flow
`readMedpc` → `getTrials(cfg)` → `addEvent(trialStruct, evConfig)` →
`extractBouts` / `eventHistogram`

The MedPC event codes are task-specific and defined by the user in `cfg.events`
(see `multipelletExample.m` for the multipellet task codes).

## Dependencies
| Dependency | Version | Why |
|---|---|---|
| MATLAB | R2020a+ | — |
| utilities_matlab | `main` (untagged) | `getEntry`, `wfig`, `avgErrorShade` |

## Rules specific to this repo
- `analysis_ephys_SIP` calls `getTrials`, `addEvent` and `extractBouts`:
  keep their inputs and output fields backward compatible.
- This repo must run on its own: `multipelletExample.m` runs from a fresh clone
  with no edits, once the dependencies listed above are on the MATLAB path.
  Dependencies on other general-purpose repos are allowed (list them under
  Dependencies and in the README); dependencies on project repos are not.

## Known issues / in progress
- `utilities_matlab` is untagged; pin a tag under Dependencies and in the README
  once it has one.
- `eventHistogram` `checkCfg` falls back to `cfg.og.events` (commented out) and
  sets `cfg.event` instead of `cfg.events` when `cfg.events` is missing.
