<div align="center">

Finnee2030
MATLAB tools for importing, organizing, and exploring LC-MS data

Project website

</div>

Overview
Finnee2030 is a MATLAB toolbox for LC-MS datasets stored in mzML format. It provides a project container, scan-level data access, and interactive tools to generate chromatographic profiles and mass spectra.

Development status: First submission. The public API and on-disk data layout may evolve.

Features
Import a single mzML file into a Finnee project

Store scan-level spectral data and acquisition metadata

Inspect project, dataset, and mzML metadata

Retrieve individual scans

Generate total-ion, base-peak, and extracted-ion profiles

Generate and plot mass spectra at selected retention times

Interactively inspect and export profile and spectrum objects in MATLAB

Quick start
matlab
% Create a project from an mzML file
myFinnee = Finnee("single", ...
    "FileIn", "path/to/file.mzML", ...
    "FolderOut", "path/to/output", ...
    "FileID", "MyProject");

% Inspect Dataset0
infoDataset(myFinnee, "Dataset0")

% Generate and plot a total-ion profile
profileTIP = getProfile(myFinnee, "Dataset0", "TIP");
profileTIP.plot

% Extract an ion profile and a spectrum
profileEIC = mkProfile(myFinnee, "Dataset0", [100 101]);
spectrum = mkSpectrum(myFinnee, "Dataset0", 5.0, [], [100 1000]);
Project layout
text
MyProject.fin/
├── myFinnee.mat
├── AquisitionData.mat
└── Dataset0/
    ├── InfoDataset.mat
    ├── InfoScan.mat
    └── Scans/
        ├── Scan#0.dat
        ├── Scan#1.dat
        └── ...
Current scope
Available now	Planned / not yet implemented
Single-file mzML import	Multiple-file and replicate workflows
Dataset0 creation and scan storage	Interpolated scan reconstruction
Scan retrieval and metadata inspection	Multi-scan spectrum combination
Profile and spectrum generation	Complete automated test suite
MATLAB visualization tools	Stable long-term API
Requirements
MATLAB with support for classdef, strings, tables, datetime, and standard graphics

An mzML file with supported metadata and binary spectral arrays

Required Finnee helper functions available on the MATLAB path

Documentation
Project website

First-submission release notes

License
BSD 3-Clause License
Copyright (c) 2026, G. Erny. All rights reserved.
