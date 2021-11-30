Set-Alias -Name ls -Value Get-ChildItem
$env:LANG = "en_CA.utf-8"
Set-PSReadlineOption -EditMode Emacs -BellStyle Visual
[Console]::TreatControlCAsInput = $True

& {
  function AddToPath {
    param([String][Parameter(Mandatory, Position = 0)]$Path)
    $env:PATH = "$Path$([IO.Path]::PathSeparator)$env:PATH"
  }

  $applicationData = [Environment]::GetFolderPath("LocalApplicationData")

  $env:RUSTUP_HOME = Join-Path $applicationData "rustup"
  $env:CARGO_HOME = Join-Path $applicationData "cargo"
  AddToPath(Join-Path $env:CARGO_HOME "bin")
  $env:OPAMROOT = Join-Path $applicationData "opam"
  AddToPath(Join-Path $HOME ".dotnet" "tools")
}

function Prompt {
  param ()

  $currentPath = $ExecutionContext.SessionState.Path.CurrentLocation
  $currentFolder = Split-Path -Leaf -Path $currentPath
  "$($currentFolder)\ 🍕 $('>' * $($NestedPromptLevel))"
}

Import-Module posh-git

if (Get-Command "opam" -ErrorAction SilentlyContinue) {
  foreach ($line in (opam env --shell zsh)) {
    if ($line -match "^(?<var>\w+)='(?<value>.*)'") {
      $var = $Matches.var
      $value = if ($IsWindows -and $var -ieq "PATH") {
        "$opamSwitchPrefix\bin;$env:PATH"
      } else {
        $Matches.value
      }

      if ($var -ieq "OPAM_SWITCH_PREFIX") {
        $value = $value -replace '\\\\', '\'
        $opamSwitchPrefix = $value
      }

      [Environment]::SetEnvironmentVariable($Matches.var, $value, "Process")
    }
  }
}
