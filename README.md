# Finnee2030

Finnee2030 is a MATLAB toolbox for **differential untargeted metabolomics** using ***profile-scan*** X-HRMS data (LC-HRMS, CE-HRMS, GC-HRMS). Instead of processing each file independently and aligning separate peak tables, it interpolates all MS scans onto a **common master m/z axis**, merges information across scans and files to build a single common peak table, and then measures peak variability in each file using a targeted approach. This design supports **ensemble averaging** and **pseudo-enhanced peak efficiency**, aiming for more consistent feature definitions and improved signal-to-noise in untargeted analyses. Finnee2030 is a work in development; for more information, see [finnee.org](https://finneeblog.wordpress.com/).

## Requirements

- **MATLAB: R2023b** or later recommended (older versions may work but are not tested).
  
- **Toolboxes**:
  - MATLAB core functionality.
  - No additional commercial toolboxes are strictly required for basic use.
  - *Optional*: Parallel Computing Toolbox.
    
- **Data format**:
  - mzML files exported from your instrument or conversion software.
  - Scans must be in profile mode (not centroided).
  - MS1 full-scan data.
  - If your data are currently in vendor format, convert them to mzML profile mode before using Finnee2030 (e.g., with [ProteoWizard msConvert](https://proteowizard.sourceforge.io/) or your instrument software).
  
## Getting started ##

- **Download Finnee2030**
  - Clone or download the repository from [GitHub](https://github.com/glerny/Finnee2030/tree/main)
  - Or download a specific release from the [Releases page](https://github.com/glerny/Finnee2030/releases).

- **Add Finnee2030 to the MATLAB path**
  - Add the main Finnee2030 folder and its subfolders to your [MATLAB path](https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html).

- **Prepare your data**
  - Export your LC-HRMS (or CE/GC-HRMS) data as mzML profile-scan files.
  - Or use one of the test data files.

- **Follow the tutorial**

## Getting help

Finnee2030 is a research-driven project. Support is provided on a best-effort basis.

- **Documentation**:  
  Start with the [Finnee2030 wiki](YOUR_GITHUB_WIKI_URL) for installation, workflow, and examples.

- **Issues**:  
  Use [GitHub Issues](YOUR_GITHUB_ISSUES_URL) for:
  - Bugs and installation problems.
  - Feature requests.
  - Data-format or compatibility questions.

- **Discussions**:  
  Use [GitHub Discussions](YOUR_GITHUB_DISCUSSIONS_URL) for:
  - General questions about using Finnee2030.
  - Ideas for new analyses or workflows.
  - Sharing experiences and tips with other users.

- **Website**:  
  Additional information, news, and contact details are available at [finnee.org](https://finnee.org).

For collaboration proposals or more detailed scientific discussions, please contact the project lead via email or through GitHub Discussions.

## Maintainers and contributors

**Project lead and main developer**  
- **G. Erny** – [affiliation, e.g., CESPU, Portugal]  
  Responsible for overall design, development, and maintenance of Finnee and Finnee2030.

**Contributors**  
Contributions to Finnee2030 may include code, documentation, example data, testing, and scientific input. Contributors are acknowledged in the repository and on the [finnee.org – About Us](https://finnee.org/about-us) page.

If you have contributed significantly and are not listed, or if you would like your contribution to be acknowledged, please open an issue or contact the project lead.

**Funding and supporting projects**  
Development of Finnee and Finnee2030 has been supported by various research projects and institutions. Details are provided on the [finnee.org – About Us](https://finnee.org/about-us) page.
