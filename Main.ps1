param(
    [Parameter(mandatory=$true)]
    [string]$DirPath
)

# Importa o script externo de OCR
. "C:\Users\l.gomes\Documents\Scripts\Call-PdfOcr.ps1"

$listaDePDFs = Get-ChildItem "$($DirPath)" -Filter "*.pdf" |
                Where-Object { $_.Name -notlike "*_ocr.pdf" }

foreach ($pdf in $listaDePDFs) {
    
    Write-Host "Processando item da fila: $($pdf.Name)..." -ForegroundColor Cyan
    
    # 1. Tenta fazer OCR via seu módulo Call-PdfOcr.ps1
    $sucesso = Call-PdfOcr -FilePath $pdf.FullName
    $ocrOriginalPath = Join-Path $pdf.DirectoryName "$($pdf.BaseName)_ocr$($pdf.Extension)"

    if ($sucesso -eq "pulado") {
        Write-Host "PULADO (OCR ja existe) -> $($pdf.Name)" -ForegroundColor Yellow
    } elseif ($sucesso -eq "ok") {
        Write-Host "OK -> $($pdf.Name)" -ForegroundColor Green
    } else {
        Write-Host "FALHA no OCR -> $($pdf.Name)" -ForegroundColor Red
        continue
    }
}