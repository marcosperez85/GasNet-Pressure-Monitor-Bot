import azure.functions as func
import json
import logging
import os
import requests
from azure.identity import DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# Configurar logging
logger = logging.getLogger()

@app.route(route="chat", methods=["POST", "OPTIONS"])
def chat(req: func.HttpRequest) -> func.HttpResponse:
    logger.info('Procesando petición para el chatbot de GasNet en Azure.')
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,x-api-key',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }

    # Manejar CORS preflight si llega directamente a la función
    if req.method == 'OPTIONS':
        return func.HttpResponse(
            status_code=200,
            headers=headers,
            body=''
        )

    try:
        # Obtener cuerpo de la petición
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}

        query = req_body.get('query', '')
        if not query:
            return func.HttpResponse(
                status_code=400,
                headers={**headers, 'Content-Type': 'application/json'},
                body=json.dumps({'error': 'Query is required'})
            )

        # Configuración de Azure AI Foundry
        endpoint = os.environ.get("AZURE_AI_FOUNDRY_ENDPOINT")
        if not endpoint:
            raise ValueError("La variable AZURE_AI_FOUNDRY_ENDPOINT no está configurada")

        # Asegurar el path completo /v1/messages
        if not endpoint.endswith("/v1/messages"):
            endpoint = f"{endpoint.rstrip('/')}/v1/messages"

        deployment_name = os.environ.get("AZURE_AI_FOUNDRY_DEPLOYMENT_NAME", "claude-3-5-sonnet")
        api_key = os.environ.get("AZURE_AI_FOUNDRY_KEY")

        # Preparar cabeceras de la petición a Azure AI Foundry
        ai_headers = {
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01"
        }

        # Autenticación: Clave API si existe, sino Managed Identity (Entra ID)
        if api_key:
            ai_headers["Authorization"] = f"Bearer {api_key}"
        else:
            logger.info("No se detectó clave API. Utilizando Managed Identity para autenticar en Azure AI Foundry...")
            credential = DefaultAzureCredential()
            token = credential.get_token("https://cognitiveservices.azure.com/.default")
            ai_headers["Authorization"] = f"Bearer {token.token}"

        # Estructura del payload según el estándar de Anthropic Messages API
        body_params = {
            "model": deployment_name,
            "system": "You are an industrial assistant specialized in operations, calculations, and process optimization. Be precise, concise, and avoid unnecessary explanations. Always respond in Spanish. Use clear structured answers. If you don't know the answer, say 'No dispongo de esa información'",
            "messages": [
                {
                    "role": "user",
                    "content": query
                }
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        }

        # Invocar Azure AI Foundry Serverless API
        response = requests.post(endpoint, headers=ai_headers, json=body_params, timeout=30)
        
        if response.status_code != 200:
            logger.error(f"Error devuelto por Azure AI Foundry ({response.status_code}): {response.text}")
            raise Exception(f"Fallo al invocar el modelo en Azure AI Foundry: {response.text}")

        response_json = response.json()
        bot_response = response_json['content'][0]['text']

        return func.HttpResponse(
            status_code=200,
            headers={**headers, 'Content-Type': 'application/json'},
            body=json.dumps({
                'response': bot_response
            })
        )

    except Exception as e:
        logger.error(f"Error en ejecución: {str(e)}")
        return func.HttpResponse(
            status_code=500,
            headers={**headers, 'Content-Type': 'application/json'},
            body=json.dumps({'error': 'Internal server error'})
        )
