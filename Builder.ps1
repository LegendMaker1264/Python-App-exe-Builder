$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$null = Add-Type -AssemblyName System.Windows.Forms
$null = Add-Type -AssemblyName System.Drawing

function Set-BuildStatus {
    param([string]$Message)

    $StatusLabel.Text = $Message
    $Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Invoke-BuildCommand {
    param(
        [string]$PythonPath,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    $Output = & $PythonPath @Arguments 2>&1
    foreach ($Line in $Output) {
        $LogBox.AppendText("$Line`r`n")
    }

    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE). See build output for details."
    }
}

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Python to EXE Builder"
$Form.Width = 680
$Form.Height = 500
$Form.MinimumSize = New-Object System.Drawing.Size(680, 500)
$Form.StartPosition = "CenterScreen"

$FilesLabel = New-Object System.Windows.Forms.Label
$FilesLabel.Text = "Python files (the first selected file is the app entry point):"
$FilesLabel.AutoSize = $true
$FilesLabel.Location = New-Object System.Drawing.Point(16, 16)
$Form.Controls.Add($FilesLabel)

$FilesBox = New-Object System.Windows.Forms.TextBox
$FilesBox.Location = New-Object System.Drawing.Point(16, 40)
$FilesBox.Width = 530
$FilesBox.ReadOnly = $true
$Form.Controls.Add($FilesBox)

$ChooseFilesButton = New-Object System.Windows.Forms.Button
$ChooseFilesButton.Text = "Browse..."
$ChooseFilesButton.Location = New-Object System.Drawing.Point(555, 38)
$ChooseFilesButton.Width = 95
$Form.Controls.Add($ChooseFilesButton)

$DependencyLabel = New-Object System.Windows.Forms.Label
$DependencyLabel.Text = "Dependency setup:"
$DependencyLabel.AutoSize = $true
$DependencyLabel.Location = New-Object System.Drawing.Point(16, 82)
$Form.Controls.Add($DependencyLabel)

$DependencyList = New-Object System.Windows.Forms.ComboBox
$DependencyList.DropDownStyle = "DropDownList"
$DependencyList.Location = New-Object System.Drawing.Point(16, 106)
$DependencyList.Width = 300
$null = $DependencyList.Items.Add("requirements.txt")
$null = $DependencyList.Items.Add("Pipenv (Pipfile + Pipfile.lock)")
$null = $DependencyList.Items.Add("No dependency file")
$DependencyList.SelectedIndex = 0
$Form.Controls.Add($DependencyList)

$UseVenvCheckBox = New-Object System.Windows.Forms.CheckBox
$UseVenvCheckBox.Text = "Use an existing virtual environment"
$UseVenvCheckBox.AutoSize = $true
$UseVenvCheckBox.Location = New-Object System.Drawing.Point(16, 148)
$Form.Controls.Add($UseVenvCheckBox)

$VenvBox = New-Object System.Windows.Forms.TextBox
$VenvBox.Location = New-Object System.Drawing.Point(16, 174)
$VenvBox.Width = 530
$VenvBox.Enabled = $false
$VenvBox.ReadOnly = $true
$Form.Controls.Add($VenvBox)

$ChooseVenvButton = New-Object System.Windows.Forms.Button
$ChooseVenvButton.Text = "Browse..."
$ChooseVenvButton.Location = New-Object System.Drawing.Point(555, 172)
$ChooseVenvButton.Width = 95
$ChooseVenvButton.Enabled = $false
$Form.Controls.Add($ChooseVenvButton)

$OutputLabel = New-Object System.Windows.Forms.Label
$OutputLabel.Text = "Save EXE in:"
$OutputLabel.AutoSize = $true
$OutputLabel.Location = New-Object System.Drawing.Point(16, 215)
$Form.Controls.Add($OutputLabel)

$OutputBox = New-Object System.Windows.Forms.TextBox
$OutputBox.Location = New-Object System.Drawing.Point(16, 239)
$OutputBox.Width = 530
$OutputBox.ReadOnly = $true
$OutputBox.Text = [Environment]::GetFolderPath("Desktop")
$Form.Controls.Add($OutputBox)

$ChooseOutputButton = New-Object System.Windows.Forms.Button
$ChooseOutputButton.Text = "Browse..."
$ChooseOutputButton.Location = New-Object System.Drawing.Point(555, 237)
$ChooseOutputButton.Width = 95
$Form.Controls.Add($ChooseOutputButton)

$BuildButton = New-Object System.Windows.Forms.Button
$BuildButton.Text = "Build EXE"
$BuildButton.Location = New-Object System.Drawing.Point(16, 278)
$BuildButton.Width = 110
$BuildButton.Height = 32
$Form.Controls.Add($BuildButton)

$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Choose Python files to get started."
$StatusLabel.AutoSize = $true
$StatusLabel.Location = New-Object System.Drawing.Point(140, 286)
$Form.Controls.Add($StatusLabel)

$LogBox = New-Object System.Windows.Forms.TextBox
$LogBox.Location = New-Object System.Drawing.Point(16, 320)
$LogBox.Width = 634
$LogBox.Height = 125
$LogBox.Multiline = $true
$LogBox.ReadOnly = $true
$LogBox.ScrollBars = "Vertical"
$LogBox.Anchor = "Top, Bottom, Left, Right"
$Form.Controls.Add($LogBox)

$FileDialog = New-Object System.Windows.Forms.OpenFileDialog
$FileDialog.Title = "Choose Python files to include in one EXE"
$FileDialog.Filter = "Python files (*.py)|*.py"
$FileDialog.CheckFileExists = $true
$FileDialog.Multiselect = $true

$ChooseFilesButton.Add_Click({
    if ($FileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $SelectedFiles = @($FileDialog.FileNames)
        $FilesBox.Text = $SelectedFiles -join "; "
        $StatusLabel.Text = "$($SelectedFiles.Count) Python file(s) selected."
    }
})

$UseVenvCheckBox.Add_CheckedChanged({
    $VenvBox.Enabled = $UseVenvCheckBox.Checked
    $ChooseVenvButton.Enabled = $UseVenvCheckBox.Checked
})

$VenvDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$VenvDialog.Description = "Select the root folder of an existing Windows virtual environment"
$VenvDialog.ShowNewFolderButton = $false
$ChooseVenvButton.Add_Click({
    if ($VenvDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $VenvBox.Text = $VenvDialog.SelectedPath
    }
})

$OutputDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$OutputDialog.Description = "Choose where to save the EXE"
$OutputDialog.ShowNewFolderButton = $true
$ChooseOutputButton.Add_Click({
    if (Test-Path -LiteralPath $OutputBox.Text -PathType Container) {
        $OutputDialog.SelectedPath = $OutputBox.Text
    }
    if ($OutputDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OutputBox.Text = $OutputDialog.SelectedPath
    }
})

$BuildButton.Add_Click({
    $SelectedFiles = @($FileDialog.FileNames)
    if ($SelectedFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Choose one or more Python files first.",
            "No Python files selected",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $EntryPoint = $SelectedFiles[0]
    $SourceDirectory = Split-Path -Parent $EntryPoint
    foreach ($SelectedFile in $SelectedFiles) {
        if ((Split-Path -Parent $SelectedFile) -ne $SourceDirectory) {
            [System.Windows.Forms.MessageBox]::Show(
                "All selected Python files must be in the same folder.",
                "Files are in different folders",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
    }

    $OutputDirectory = $OutputBox.Text
    if ([string]::IsNullOrWhiteSpace($OutputDirectory) -or
        -not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Choose an existing folder for the EXE.",
            "Output folder not selected",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $AppName = [IO.Path]::GetFileNameWithoutExtension($EntryPoint)
    $BuildEnvironment = Join-Path $SourceDirectory ".build-venv"
    if ($UseVenvCheckBox.Checked) {
        if ([string]::IsNullOrWhiteSpace($VenvBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Browse to an existing virtual environment, or uncheck the option to use the builder's local environment.",
                "Virtual environment not selected",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
        $BuildEnvironment = $VenvBox.Text
    }
    $BuildPython = Join-Path $BuildEnvironment "Scripts\python.exe"

    $RequirementsFile = Join-Path $SourceDirectory "requirements.txt"
    $Pipfile = Join-Path $SourceDirectory "Pipfile"
    $PipfileLock = Join-Path $SourceDirectory "Pipfile.lock"
    $BuildDirectory = Join-Path $SourceDirectory ".exe-build"
    $DependencyChoice = [string]$DependencyList.SelectedItem

    $BuildButton.Enabled = $false
    $LogBox.Clear()
    try {
        Push-Location $SourceDirectory
        try {
            if (-not (Test-Path -LiteralPath $BuildPython -PathType Leaf)) {
                if ($UseVenvCheckBox.Checked) {
                    throw "The selected folder does not contain a Windows virtual environment (expected Scripts\python.exe): $BuildEnvironment"
                }

                Set-BuildStatus "Creating local build environment..."
                $PythonLauncher = Get-Command "py" -ErrorAction SilentlyContinue
                if ($null -ne $PythonLauncher) {
                    & $PythonLauncher.Source -3 -m venv $BuildEnvironment
                }
                else {
                    $PythonCommand = Get-Command "python" -ErrorAction SilentlyContinue
                    if ($null -eq $PythonCommand) {
                        throw "Python 3 was not found. Install Python and ensure the 'py' or 'python' command is available."
                    }
                    & $PythonCommand.Source -m venv $BuildEnvironment
                }
                if ($LASTEXITCODE -ne 0) {
                    throw "Could not create the local build environment (exit code $LASTEXITCODE)."
                }
            }

            Set-BuildStatus "Installing PyInstaller..."
            Invoke-BuildCommand $BuildPython @("-m", "pip", "install", "pyinstaller") "Installing PyInstaller failed"

            if ($DependencyChoice -eq "requirements.txt") {
                if (-not (Test-Path -LiteralPath $RequirementsFile -PathType Leaf)) {
                    throw "No requirements.txt was found at: $RequirementsFile"
                }
                Set-BuildStatus "Installing requirements.txt..."
                Invoke-BuildCommand $BuildPython @("-m", "pip", "install", "-r", $RequirementsFile) "Installing project requirements failed"
            }
            elseif ($DependencyChoice -eq "Pipenv (Pipfile + Pipfile.lock)") {
                if (-not (Test-Path -LiteralPath $Pipfile -PathType Leaf)) {
                    throw "No Pipfile was found at: $Pipfile"
                }
                if (-not (Test-Path -LiteralPath $PipfileLock -PathType Leaf)) {
                    throw "No Pipfile.lock was found at: $PipfileLock"
                }

                Set-BuildStatus "Installing Pipenv..."
                Invoke-BuildCommand $BuildPython @("-m", "pip", "install", "pipenv") "Installing Pipenv failed"
                Set-BuildStatus "Exporting locked Pipenv dependencies..."
                $PipenvRequirements = & $BuildPython -m pipenv requirements 2>&1
                if ($LASTEXITCODE -ne 0) {
                    foreach ($Line in $PipenvRequirements) {
                        $LogBox.AppendText("$Line`r`n")
                    }
                    throw "Exporting dependencies from Pipfile.lock failed (exit code $LASTEXITCODE)."
                }

                $PipenvRequirementsText = $PipenvRequirements -join [Environment]::NewLine
                if (-not [string]::IsNullOrWhiteSpace($PipenvRequirementsText)) {
                    New-Item -ItemType Directory -Path $BuildDirectory -Force | Out-Null
                    $PipenvRequirementsFile = Join-Path $BuildDirectory "pipenv-requirements.txt"
                    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [IO.File]::WriteAllText($PipenvRequirementsFile, $PipenvRequirementsText, $Utf8NoBom)
                    try {
                        Set-BuildStatus "Installing Pipenv dependencies..."
                        Invoke-BuildCommand $BuildPython @("-m", "pip", "install", "-r", $PipenvRequirementsFile) "Installing Pipenv dependencies failed"
                    }
                    finally {
                        if (Test-Path -LiteralPath $PipenvRequirementsFile -PathType Leaf) {
                            Remove-Item -LiteralPath $PipenvRequirementsFile
                        }
                    }
                }
            }

            $PyInstallerArguments = @(
                "--noconfirm",
                "--clean",
                "--onefile",
                "--windowed",
                "--name", $AppName,
                "--distpath", $OutputDirectory,
                "--workpath", (Join-Path $BuildDirectory "work"),
                "--specpath", $BuildDirectory,
                "--paths", $SourceDirectory
            )

            foreach ($SelectedFile in $SelectedFiles | Select-Object -Skip 1) {
                $ModuleName = [IO.Path]::GetFileNameWithoutExtension($SelectedFile)
                if ($ModuleName -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
                    throw "Support file '$SelectedFile' is not a valid Python module filename and cannot be added as a hidden import."
                }
                $PyInstallerArguments += @("--hidden-import", $ModuleName)
            }
            $PyInstallerArguments += $EntryPoint

            Set-BuildStatus "Building $AppName.exe..."
            Invoke-BuildCommand $BuildPython (@("-m", "PyInstaller") + $PyInstallerArguments) "PyInstaller failed"

            $ExecutablePath = Join-Path $OutputDirectory "$AppName.exe"
            if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
                throw "Build finished without producing the expected executable: $ExecutablePath"
            }

            Set-BuildStatus "Build complete."
            $LogBox.AppendText("Created: $ExecutablePath`r`n")
            [System.Windows.Forms.MessageBox]::Show(
                "Created application:`r`n$ExecutablePath",
                "Build complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
        finally {
            Pop-Location
        }
    }
    catch {
        Set-BuildStatus "Build failed."
        $LogBox.AppendText("ERROR: $($_.Exception.Message)`r`n")
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Build failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        $BuildButton.Enabled = $true
    }
})

$Form.Add_Shown({
    $Form.Activate()
})

$null = $Form.ShowDialog()
