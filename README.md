# scoop-cudnn-bucket

A Scoop bucket for NVIDIA cuDNN Windows x86_64 redistributable archives.

## Packages

- `cudnn-cuda12`: cuDNN for CUDA 12
- `cudnn-cuda13`: cuDNN for CUDA 13

The manifests install the archive contents into Scoop's app directory, add `bin\x64` to `PATH`, and set `CUDNN_HOME` to the installed directory.

## Install

```powershell
scoop bucket add cudnn https://github.com/<your-user>/<your-repo>
scoop install cudnn-cuda12
# or
scoop install cudnn-cuda13
```

After installation, the layout is expected to be:

```text
$env:CUDNN_HOME\bin\x64\*.dll
$env:CUDNN_HOME\include\*.h
$env:CUDNN_HOME\lib\x64\*.lib
```

## Automatic updates

The GitHub Actions workflow runs daily and on manual dispatch. It reads NVIDIA's cuDNN redist index, opens the newest `redistrib_*.json`, and updates both manifests with:

- full cuDNN package version, for example `9.22.0.52`
- Windows x86_64 CUDA-specific archive URL
- NVIDIA-provided SHA256
- archive `extract_dir`

The workflow creates a pull request when changes are found.

## Manual update

```powershell
./bin/update-cudnn.ps1
```

## Notes

cuDNN is distributed under NVIDIA's cuDNN license. This bucket does not mirror NVIDIA files; it only points Scoop to NVIDIA's official redist URLs.
