import azure.functions as func
import json
import logging
import os
import requests
from openai import OpenAI

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

        # Configuración de OpenAI
        endpoint = os.environ.get("OPENAI_ENDPOINT", "https://api.openai.com/v1")
        deployment_name = os.environ.get("OPENAI_DEPLOYMENT_NAME", "gpt-5.1")
        api_key = os.environ.get("OPENAI_API_KEY")

        # Preparar cliente de OpenAI
        client = OpenAI(
            base_url=endpoint,
            api_key=api_key
        )

        # Invocar el modelo de OpenAI
        response = client.create_response(
            model=deployment_name,
            input=query
        )

        return func.HttpResponse(
            status_code=200,
            headers={**headers, 'Content-Type': 'application/json'},
            body=json.dumps({
                'response': response.output[0]
            })
        )

    except Exception as e:
        import traceback

        logger.exception(e)

        return func.HttpResponse(
            status_code=500,
            body=json.dumps({
                "error": str(e),
                "trace": traceback.format_exc()
            }),
            mimetype="application/json"
        )