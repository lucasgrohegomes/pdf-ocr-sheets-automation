function Call-PdfOcr {
	param(
		[Parameter(mandatory=$true)]
		[string]$FilePath
	)

	$exePath	= "C:\Program Files\PDF24\pdf24-Ocr.exe"
	$file		= Get-Item $FilePath
	$outPath	= Join-Path $file.DirectoryName "$($file.BaseName)_ocr$($file.Extension)"

	# Caminho para descartar o log em vez de jogar na tela
    $nullPath = [System.IO.Path]::GetTempFileName()
	
	if (Test-Path $outPath) 
	{
		return "pulado"
	}

    # Executa o processo de forma silenciosa e aguarda a conclusão. Os dados do console são passados para um arquivo da variável que será deletada.
    $process = Start-Process -FilePath $exePath `
                             -ArgumentList "-file `"$($file.FullName)`" -outputFile `"$outPath`" -language por" `
                             -RedirectStandardOutput $nullPath `
                             -NoNewWindow `
                             -PassThru `
                             -Wait

    # Limpa o arquivo temporário de log
    if (Test-Path $nullPath) { Remove-Item $nullPath -Force }
	
	if (Test-Path $outPath) 
	{
		return "ok"
	}
	else 
	{
		return "falha"
	}
}