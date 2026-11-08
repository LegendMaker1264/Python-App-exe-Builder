# Python App EXE Builder

A Windows PowerShell GUI for packaging a Python application into a single
Windows executable with PyInstaller.

## Requirements

- Windows
- Windows PowerShell
- Python 3, available through the `py` launcher or `python` command

The builder creates a local `.build-venv` beside the selected Python files
unless you choose to use an existing virtual environment. It installs
PyInstaller into that environment and, when selected, installs project
dependencies from `requirements.txt` or a Pipenv lock file.

## Usage

1. Download or clone this repository.
2. Run `Builder.ps1` in Windows PowerShell.
3. Select one or more `.py` files from the same directory. The first selected
   file is the application's entry point; additional files are included as
   hidden imports.
4. Choose how to install dependencies and, optionally, select an existing
   virtual environment.
5. Choose an output folder and select **Build EXE**.

The resulting `<entry-point-name>.exe` is written to the selected output folder.
The builder uses PyInstaller's `--onefile` and `--windowed` options.

## Notes

- All selected Python files must be in the same folder.
- Additional Python files must have valid Python module names.
- Selecting `requirements.txt` requires that file to be in the source folder.
- Selecting Pipenv requires both `Pipfile` and `Pipfile.lock` in the source
  folder.
- Builds are Windows executables and should be produced on Windows for Windows.
