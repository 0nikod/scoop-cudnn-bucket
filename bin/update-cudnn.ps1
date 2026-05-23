param(
    [string]$RootUrl = 'https://developer.download.nvidia.com/compute/cudnn/redist/',
    [string]$BucketDir = (Join-Path $PSScriptRoot '..' 'bucket')
)

$ErrorActionPreference = 'Stop'

function Get-LatestCudnnReleaseForCudaVariant {
    param(
        [ValidateSet('cuda12', 'cuda13')]
        [string]$CudaVariant
    )

    $index = Invoke-WebRequest -UseBasicParsing -Uri $RootUrl
    $labels = [regex]::Matches($index.Content, 'redistrib_([0-9]+(?:\.[0-9]+)+)\.json') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object { [version]$_ } -Descending |
        Select-Object -Unique

    foreach ($label in $labels) {
        $jsonUrl = "${RootUrl}redistrib_${label}.json"
        $json = Invoke-RestMethod -Uri $jsonUrl
        $artifact = $json.cudnn.'windows-x86_64'.$CudaVariant
        if ($null -ne $artifact) {
            return [pscustomobject]@{
                ReleaseLabel = $json.release_label
                Version      = $json.cudnn.version
                RelativePath = $artifact.relative_path
                Sha256       = $artifact.sha256
                JsonUrl      = $jsonUrl
            }
        }
    }

    throw "No cuDNN Windows x86_64 artifact found for $CudaVariant."
}

function Update-Manifest {
    param(
        [ValidateSet('cuda12', 'cuda13')]
        [string]$CudaVariant,
        [string]$ManifestName
    )

    $release = Get-LatestCudnnReleaseForCudaVariant -CudaVariant $CudaVariant
    $manifestPath = Join-Path $BucketDir $ManifestName
    $manifest = Get-Content -Raw -Path $manifestPath | ConvertFrom-Json

    $url = $RootUrl + $release.RelativePath
    $leaf = Split-Path -Leaf $release.RelativePath
    $extractDir = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($leaf))

    $manifest.version = $release.Version
    $manifest.architecture.'64bit'.url = $url
    $manifest.architecture.'64bit'.hash = $release.Sha256
    $manifest.architecture.'64bit'.extract_dir = $extractDir

    $json = $manifest | ConvertTo-Json -Depth 20
    Set-Content -Path $manifestPath -Value ($json + [Environment]::NewLine) -Encoding UTF8

    Write-Host "Updated $ManifestName to cuDNN $($release.Version) from $($release.JsonUrl)"
}

Update-Manifest -CudaVariant cuda12 -ManifestName 'cudnn-cuda12.json'
Update-Manifest -CudaVariant cuda13 -ManifestName 'cudnn-cuda13.json'
