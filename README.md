# Finnee2030
Finnee2030 is a MATLAB toolbox for **differential untargeted metabolomics** using ***profile-scan*** X-HRMS data (LC-HRMS, CE-HRMS, GC-HRMS). Instead of processing each file independently and aligning separate peak tables, it interpolates all MS scans onto a **common master m/z axis**, merges information across scans and files to build a single common peak table, and then measures peak variability in each file using a targeted approach. This design supports **ensemble averaging** and **pseudo-enhanced peak efficiency**, aiming for more consistent feature definitions and improved signal-to-noise in untargeted analyses. Finnee2030 is a work in development; for more information, see [finnee.org](https://finneeblog.wordpress.com/).

## Requirements
+ **MATLAB: R2023b** or later recommended (older versions may work but are not tested).
+ **Toolboxes**: \
                - MATLAB core functionality.\
                - No additional commercial toolboxes are strictly required for basic use.\
                - *Optional*: Parallel Computing Toolbox.

+ **Data format**:\
                  - mzML files exported from your instrument or conversion software.\
                  - Scans must be in profile mode (not centroided).\
                  - MS1 full-scan data.\
                  - If your data are currently in vendor format, convert them to mzML profile mode before using Finnee2030 (e.g., with [ProteoWizard msConvert](https://proteowizard.sourceforge.io/) or your instrument software).
  
## Getting started ##
+ **Download Finnee2030** \
                  - Clone or download the repository from [GitHub]([https://github.com/YOUR_USERNAME/](https://github.com/glerny/Finnee2030/tree/main)) \
                  - Or download a specific release from the [Releases page](https://github.com/glerny/Finnee2030/releases).

+ **Add Finnee2030 to the MATLAB path** \
                  - Add the main Finnee2030 folder and its subfolders to your MATLAB path.

+ **Prepare your data** \
                  - Export your LC-HRMS (or CE/GC-HRMS) data as mzML profile-scan files.
                  - Or use one of the test data files.
4. Follow the tutorial
