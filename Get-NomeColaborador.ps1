#function Get-NomeColaborador {
	param(
		[Parameter(mandatory=$true)]
		[string]$OcrFilePath
	)
	
	$ocrText	= & pdftotext.exe -enc UTF-8 $OcrFilePath -
#	Write-Host $ocrText

	# Modelo de json para servir como molde para o output.
    $jsonSchema = @{
        type = "object"
        properties = @{
            name = @{
                type = "string"
                description = "O nome completo do colaborador ou titular sobre o qual o documento se refere. Retorne 'Não encontrado.' se não houver."
            }
        }
        required = @("name")
    }
	
	$systemPrompt = @"
Você é um especialista em análise de documentos corporativos.
Sua missão é identificar a PESSOA PRINCIPAL sobre a qual o texto trata (o colaborador, paciente, funcionário ou titular do documento).

REGRAS CRÍTICAS DE EXTRAÇÃO:
1. DESCONSIDERE nomes que aparecem em cabeçalhos, rodapés ou metadados de sistemas (ex: 'Impresso por', 'Gerado por', 'Usuário:', 'Operador:', 'Atendente:', 'Analista:', 'Assinado por'). Nomes que representem o operador/sistema devem ser IGNOARADOS.
2. O colaborador principal é a pessoa citada no CORPO DO TEXTO, sobre a qual o relatório, atestado, holerite ou documento se refere repetidamente.
3. Se houver mais de um nome, escolha SEMPRE aquele que é o SUJEITO/FOCO da análise do documento, e não quem gerou ou imprimiu o arquivo.
4. Ignorar linhas de código PHP, JavaScript e lógica interna, apenas focando no conteúdo textual do documento.
"@

	$userPrompt   = "Texto do documento:`n$ocrText"

	Write-Host "Checkpoint 2."
	
	$bodyObject	= @{
		model = "llama3.2:3b"
        system  = $systemPrompt
        prompt  = $userPrompt
        stream  = $false
        format  = $jsonSchema		# Passando o esquema de json direto no formato, 
									# para que o retorno venha de acordo.
        options = @{
            temperature = 0.0		# Configurando limite de input de dados 
            num_ctx     = 8192		# e criatividade.
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
#}