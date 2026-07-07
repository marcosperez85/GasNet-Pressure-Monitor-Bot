import azure.functions as func
import json
import logging
import os

from openai import OpenAI

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

logger = logging.getLogger(__name__)


@app.route(route="chat", methods=["POST", "OPTIONS"])
def chat(req: func.HttpRequest) -> func.HttpResponse:

    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,x-api-key",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
    }

    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers=headers,
        )

    try:

        body = req.get_json()

        query = body.get("query")

        if not query:
            return func.HttpResponse(
                json.dumps({"error": "query is required"}),
                status_code=400,
                mimetype="application/json",
                headers=headers,
            )

        endpoint = os.environ["AZURE_AI_FOUNDRY_ENDPOINT"]
        deployment = os.environ["AZURE_AI_FOUNDRY_DEPLOYMENT_NAME"]
        api_key = os.environ["AZURE_AI_FOUNDRY_KEY"]

        client = OpenAI(
            base_url=endpoint,
            api_key=api_key,
        )

        response = client.responses.create(
            model=deployment,
            input=query,
        )

        answer = response.output_text

        return func.HttpResponse(
            json.dumps({"response": answer}),
            status_code=200,
            mimetype="application/json",
            headers=headers,
        )

    except Exception as e:
        import traceback

        logger.exception(e)

        return func.HttpResponse(
            status_code=500,
            mimetype="application/json",
            body=json.dumps({
                "error": str(e),
                "trace": traceback.format_exc()
            })
        )