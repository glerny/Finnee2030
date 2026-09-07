# Finnee2030
Finnee2030 is a MATLAB toolbox for differential untargeted analysis of profile-scan X-HRMS data (LC-HRMS, CE-HRMS, GC-HRMS). Instead of processing each file independently and aligning separate peak tables, it interpolates all MS scans onto a common master m/z axis, merges information across scans and files to build a single common peak table, and then measures peak variability in each file using a targeted approach. This design supports ensemble averaging and pseudo-enhanced peak efficiency, and is intended for researchers who want a transparent, controllable workflow for comparing samples rather than a fully automated metabolite-identification pipeline.

## Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/yourname/MyProject.git
cd MyProject
pip install -r requirements.txt

Usage

Run the main script on your dataset:

python classify_cats.py --input data/cats/

Example Output

License

MIT License © 2025 Your Name
