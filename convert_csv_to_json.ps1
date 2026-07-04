$assetDir = "D:\projek-flutter\mida\assets"
$csvDir = "$assetDir\data"

# Function to write JSON array to file
function Write-JsonFile {
    param($data, $path)
    $json = $data | ConvertTo-Json -Compress
    Set-Content -Path $path -Value $json -Encoding UTF8
    Write-Host "Created: $path ($($data.Count) entries)"
}

# ---- ICD-10 ----
$icd10csv = Get-Content -LiteralPath "$csvDir\[PUBLIC] ICD-10 e-klaim.xlsx - ICD10.csv" | ConvertFrom-Csv
$icd10 = $icd10csv | Where-Object { $_.CODE -and $_.CODE.Trim() -ne '' } | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.DISPLAY.Trim()
    }
}
Write-JsonFile -data $icd10 -path "$assetDir\icd10.json"

# ---- ICD-9-CM ----
$icd9csv = Get-Content -LiteralPath "$csvDir\[PUBLIC] ICD-9CM e-klaim.xlsx - ICD9 CM.csv" | ConvertFrom-Csv
$icd9 = $icd9csv | Where-Object { $_.CODE -and $_.CODE.Trim() -ne '' } | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.DISPLAY.Trim()
    }
}
Write-JsonFile -data $icd9 -path "$assetDir\icd_9cm.json"

# ---- ICD-MM ----
$icdmcsv = Get-Content -LiteralPath "$csvDir\[PUBLIC] ICD-MM (Maternal Mortality) - ICD-MM [SHARE].csv" | ConvertFrom-Csv
$icdmm = $icdmcsv | Where-Object {
    $_.CODE -and $_.CODE.Trim() -ne '' -and
    $_.VERSION -and $_.VERSION.Trim() -ne '' -and
    $_.CODE.Trim() -notlike 'GROUP-*'
} | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.DISPLAY.Trim()
    }
}
Write-JsonFile -data $icdmm -path "$assetDir\icd_mm.json"

# ---- ICD-PM ----
$icdpmcsv = Get-Content -LiteralPath "$csvDir\[PUBLIC] ICD-PM (Perinatal Mortality)  - ICD-10 PM SHARE.csv" | ConvertFrom-Csv
$icdpm = $icdpmcsv | Where-Object {
    $_.VERSION -and $_.VERSION.Trim() -eq 'ICD_PM'
} | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.DISPLAY.Trim()
    }
}
Write-JsonFile -data $icdpm -path "$assetDir\icd_pm.json"

# ---- ICD-O Morphology ----
$morphcsv = Get-Content -LiteralPath "$csvDir\Morphology (ICD-O-3 2nd Revision) - Morphology ICD-O.csv" | ConvertFrom-Csv
$morph = $morphcsv | Where-Object { $_.CODE -and $_.CODE.Trim() -ne '' } | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.STR.Trim()
        chapter = 'Morphology'
        chapter_title = 'Morphology of neoplasms'
    }
}

# ---- ICD-O Topography ----
$topocsv = Get-Content -LiteralPath "$csvDir\Topography (ICD-O) - Topography ICD-O.csv" | ConvertFrom-Csv
$topo = $topocsv | Where-Object { $_.CODE -and $_.CODE.Trim() -ne '' } | ForEach-Object {
    [PSCustomObject]@{
        code = $_.CODE.Trim()
        description = $_.STR.Trim()
        chapter = 'Topography'
        chapter_title = 'Topography of neoplasms'
    }
}

# Combine ICD-O
$icdo = $morph + $topo
Write-JsonFile -data $icdo -path "$assetDir\icd_o.json"

Write-Host "`nAll conversions complete!"
