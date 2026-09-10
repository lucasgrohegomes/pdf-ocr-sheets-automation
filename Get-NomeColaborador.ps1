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
                description = "O nome completo do colaborador ou titular sobre o qual o documento se refere. Retorne 'Não encontrado.' se não houver."
            }
        }
        required = @("owner_name")
    }
	
	$systemPrompt = @"
Você é um extrator de entidades focado EXCLUSIVAMENTE em NOMES DE PESSOAS FÍSICAS.
Sua TAREFA ÚNICA é extrair o NOME PRÓPRIO COMPLETO do colaborador ou titular humano (ex: 'Natalis Del Valle Bello Castro').

REGRAS OBRIGATÓRIAS DE EXCLUSÃO:
1. O valor retornado DEVE ser obrigatoriamente o NOME DE UMA PESSOA (Humano).
2. NUNCA retorne títulos de documentos, seções ou contratos (EXEMPLOS PROIBIDOS: 'Contrato de Trabalho', 'Detalhamento do Salário', 'Holerite', 'Atestado Médico', 'Folha de Pagamento', 'Ficha Cadastral').
3. NUNCA retorne cargos, departamentos ou nomes de empresas (EXEMPLOS PROIBIDOS: 'Auxiliar de Cozinha', 'SESI', 'SENAI', 'Recursos Humanos').
4. NUNCA retorne nomes de operadores de sistema ou quem assinou o documento.
5. Se não encontrar um NOME DE PESSOA HUMANA claro no texto, retorne exatamente: "Não encontrado."
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
		return $result.owner_name
    }
    catch {
        Write-Error "Erro ao processar: $_"
        return $null
    }
}