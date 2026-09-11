param(
    [Parameter(mandatory=$true)]
    [string]$DirPath
)

# Importa o script externo de OCR e o script externo que introduz o OCR à IA pra puxar o nome do colaborador.
. "C:\Users\l.gomes\Documents\Scripts\pdf-ocr-sheets-automation\Call-PdfOcr.ps1"
. "C:\Users\l.gomes\Documents\Scripts\pdf-ocr-sheets-automation\Get-NomeColaborador.ps1"

Write-Host ""

$listaDePDFs = Get-ChildItem "$($DirPath)" -Filter "*.pdf" |
                Where-Object { $_.Name -notlike "*_ocr.pdf" }

foreach ($pdf in $listaDePDFs) 
{
    Write-Host "Processando item da fila: $($pdf.Name)..." -ForegroundColor Cyan
    $sucessoOcr = Call-PdfOcr -FilePath $pdf.FullName
	
    if ($sucessoOcr -eq "pulado") 
	{
        Write-Host "PULADO (OCR ja existe) -> $($pdf.Name)" -ForegroundColor Yellow
		
		# Tenta fazer OCR via seu módulo Call-PdfOcr.ps1
		$ocrFile = Join-Path $pdf.DirectoryName "$($pdf.BaseName)_ocr$($pdf.Extension)"
		$sucessoNome = Get-NomeColaborador -OcrFilePath $ocrFile
		Rename-Item -Path $ocrFile -NewName "$($sucessoNome)_ocr.pdf"
		Write-Host "$($pdf.BaseName)_ocr$($pdf.Extension) -Renomeado-> $($sucessoNome)_ocr.pdf" -ForegroundColor Yellow
    } 
	elseif ($sucessoOcr -eq "ok") 
	{
        Write-Host "OK -> $($pdf.Name)" -ForegroundColor Green
		
		# Tenta puxar o nome do colaborador com IA Ollama local e depois renomeia o OCR.
		$ocrFile = Join-Path $pdf.DirectoryName "$($pdf.BaseName)_ocr$($pdf.Extension)"
		$sucessoNome = Get-NomeColaborador -OcrFilePath $ocrFile
		Rename-Item -Path $ocrFile -NewName "$($sucessoNome)_ocr.pdf"
		Write-Host "$($pdf.BaseName)_ocr$($pdf.Extension) -Renomeado-> $($sucessoNome)_ocr.pdf" -ForegroundColor Yellow
    } 
	else 
	{
        Write-Host "FALHA no OCR -> $($pdf.Name)" -ForegroundColor Red
        continue
    }
	Write-Host ""
}