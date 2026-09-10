function Get-NomeColaborador {
	param(
		[Parameter(mandatory=$true)]
		[string]$OcrFilePath
	)
	
	$ocrText	= & pdftotext.exe -f 1 -l 10 -enc UTF-8 $OcrFilePath -
#	Write-Host $ocrText

	# Modelo de json para servir como molde para o output.
    $jsonSchema = @{
        type = "object"
        properties = @{
            owner_name = @{
                type = "string"
                description = "Apenas UM NOME COMPLETO sem vírgulas, sem listas e sem abreviações duplicadas."
            }
        }
        required = @("owner_name")
    }
	
	$systemPrompt = @"
Você é um extrator de dados estrito. Sua tarefa é extrair o NOME COMPLETO da pessoa física principal.

REGRAS RÍGIDAS DE FORMATAÇÃO:
1. Retorne apenas UM ÚNICO NOME COMPLETO (ex: 'Natalis Del Valle Bello Castro').
2. NUNCA use vírgulas, NUNCA concatene múltiplos nomes e NUNCA crie listas (PROIBIDO: 'M. Castro, Natalis Del Valle Bello Castro').
3. Se o nome aparecer de formas diferentes (ex: abreviado e completo), escolha SEMPRE a versão mais completa e por extenso.
4. Desconsidere títulos de documentos, cargos, nomes de empresas e operadores de sistema.
"@

	$userPrompt   = "Texto do documento:`n$ocrText"
	
	$bodyObject	= @{
		model 			= "llama3.2:3b"
        system  		= $systemPrompt
        prompt  		= $userPrompt
        stream  		= $false
        format  		= $jsonSchema		# Passando o esquema de json direto no formato, 
											# para que o retorno venha de acordo.
									
		keep_alive 		= 0					# Zera o tempo de vida da IA pra evitar que degrade
											# após varios docs, levando a alucinação.
        options 		= @{
            temperature = 0.0				# Configurando limite de input de dados 
            num_ctx     = 4096				# e criatividade.
        }
	}
	
	$jsonString = $bodyObject | ConvertTo-Json -Depth 10
    $utf8Bytes  = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	
	try {
		# API do Ollama.
		$response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
                                      -Method Post `
                                      -Body $utf8Bytes `
                                      -ContentType "application/json; charset=utf-8"

		Write-Host "--- Resposta Bruta do Ollama ---" -ForegroundColor Cyan
		Write-Host $response.response -ForegroundColor Gray
		Write-Host "--------------------------------" -ForegroundColor Cyan

		$result = $response.response | ConvertFrom-Json
		$nomeExtraido = $result.owner_name

		# Se o modelo devolver nomes separados por vírgula, pega o nome mais longo (o completo)
		if ($nomeExtraido -and $nomeExtraido.Contains(",")) {
			$listaNomes = $nomeExtraido -split "," | ForEach-Object { $_.Trim() }
			# Ordena pelo tamanho do texto e pega o maior (ex: prefere "Natalis Del Valle..." ao invés de "M. Castro")
			$nomeExtraido = ($listaNomes | Sort-Object Length -Descending)[0]
		}

    return $nomeExtraido
    }
    catch {
        Write-Error "Erro ao processar: $_"
        return $null
    }
}