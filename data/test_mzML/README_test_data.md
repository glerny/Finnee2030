# LIST OF DATA FILES

## 1. **example0001_DDA_profile.mzML**, **example0002_FS_profile.mzML** and **example0003_FS_centroid.mzML**
### Test Data Provenance: Salivary Metabolome in Pediatric Eosinophilic Esophagitis (ST003133) [1]
The test files distributed with the Finnee2030 toolbox are derived from two unaltered raw LC–MS files from Metabolomics Workbench Study ST003133 (“Unraveling Salivary Metabolome in Children with Eosinophilic Esophagitis: Insights into Disease Pathogenesis and Translational Potential”), Project PR001946, submitted by S. Codreanu, Department of Chemistry, Center for Innovative Technology, Vanderbilt University. This pilot, untargeted metabolomics study profiled saliva from 28 pediatric subjects across four groups (active EoE, inactive EoE, GERD negative controls, and non-EoE positive controls) to investigate upstream metabolomic alterations associated with EoE and to assess the translational potential of salivary biomarkers. Data were acquired on a Thermo Vanquish UHPLC coupled to a Thermo Q Exactive HF hybrid Orbitrap mass spectrometer in positive-ion ESI mode, using HILIC separation. Full-scan MS was recorded at 120,000 resolution (AGC target 1 × 10⁶) and DDA MS/MS spectra at 15,000 resolution.

### Original .raw files:
The following files were used to make the mzML test files
 - SC_20230617_aHILICp_FMS_Locke_Act8.raw (full scan mode)
 - SC_20230617_aHILICp_DDA2_Locke_QC_13 (DDA)

### Test mzML data files
Original raw files were converted to mzML with [msConvert](https://proteowizard.sourceforge.io/index.html). For profile mode MS scans, no filters were used. MS scans were converted to centroid if needed, using the **Peak Picking Filter** with the **Vendor Algorithm**.
 - **example0001_DDA_profile.mzML**: SC_20230617_aHILICp_DDA2_Locke_QC_13 converted to mzML file format with profile MS scans
 - **example0002_FS_profile.mzML**:  SC_20230617_aHILICp_FMS_Locke_Act8.raw converted to mzML file format with profile MS scans
 - **example0003_FS_centroid.mzML**: SC_20230617_aHILICp_FMS_Locke_Act8.raw converted to mzML file format with centroid MS scans

These files are provided solely as reduced, non-commercial test data for developing and validating the Finnee2030 toolbox; they do not reproduce the study publication, protocols, or annotations beyond the information necessary for provenance. Users should cite Metabolomics Workbench Project PR001946 / Study ST003133 (DOI: https://doi.org/10.21228/M85X5N) and consult the current Metabolomics Workbench Terms of Use and data-sharing policy before any reuse, redistribution, or publication based on these files.

## References
	 [1] This data is available at the NIH Common Fund's National Metabolomics Data Repository (NMDR) website, the Metabolomics Workbench, https://www.metabolomicsworkbench.org, where it has been assigned Project ID PR001946. The data can be accessed directly via it's Project DOI: 10.21228/M85X5N. This work is supported by NIH grant, U2C- DK119886. See: https://www.metabolomicsworkbench.org/about/howtocite.php
