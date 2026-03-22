let rootElement = EMBED.getRootElement();
let data = EMBED.getComponent().schema.data;

export const $API_GATEWAY_URL = data.API_GATEWAY_URL.manual;
export const $API_GATEWAY_API_KEY = data.API_GATEWAY_API_KEY.manual;

const chatbot_endpoint = $API_GATEWAY_URL.endsWith('/chat') ?
    $API_GATEWAY_URL :
    `${$API_GATEWAY_URL}/chat`;

// jQuery selectors
const $cuadroParaUserInput = $('#cuadroParaUserInput');
const $chatBox = $('#chat-box');
const $sendButton = $('#sendButton');

// Agregar evento para los botones de navegación
$('.navButton').on('click', function() {
    if ($(this).text().includes('Map View')) {
        EMBED.executeAction("onClickedMapViewButton");
    }
});

// Agregar evento click para el botón de envío
$sendButton.on('click', function() {
    sendMessage();
});

async function sendMessage() {
    const textoDelUsuario = $cuadroParaUserInput.val();

    if (!textoDelUsuario) return;

    $cuadroParaUserInput.val("");

    // Añadir la clase 'user-message' para facilitar el estilizado
    $chatBox.append(`<p class="user-message"><strong>Tú:</strong> ${textoDelUsuario}</p>`);
    $chatBox.scrollTop($chatBox[0].scrollHeight);

    // Mostrar indicador de carga
    const loadingId = `loading-${Date.now()}`;
    $chatBox.append(`<p id="${loadingId}" class="bot-loading"><em><i class="fas fa-spinner fa-spin"></i> Escribiendo...</em></p>`);
    $chatBox.scrollTop($chatBox[0].scrollHeight);

    try {
        const response = await fetch(chatbot_endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": $API_GATEWAY_API_KEY
            },
            body: JSON.stringify({ query: textoDelUsuario })
        });

        // Eliminar indicador de carga
        $(`#${loadingId}`).remove();

        if (response.ok) {
            // Leer la respuesta como texto primero
            let textResponse = await response.text();

            // Intentar parsear como JSON
            try {
                const jsonResponse = JSON.parse(textResponse);

                // Función para preservar saltos de línea y formatear texto
                function formatText(text) {
                    // Reemplazar saltos de línea con <br> para HTML
                    return text.replace(/\n/g, '<br>');
                }

                // Añadir la clase 'bot-message' para facilitar el estilizado
                if (jsonResponse && typeof jsonResponse === 'object' && jsonResponse.response) {
                    $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ${formatText(jsonResponse.response)}</p>`);
                } else if (jsonResponse && typeof jsonResponse === 'object' && jsonResponse.body) {
                    $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ${formatText(jsonResponse.body)}</p>`);
                } else {
                    // Si es JSON pero sin body o response, mostrar como texto
                    $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ${formatText(textResponse)}</p>`);
                }
            } catch (e) {
                // Si no es JSON válido, mostrar el texto directamente
                $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ${textResponse.replace(/\n/g, '<br>')}</p>`);
            }
        } else {
            $chatBox.append(`<p class="error-message"><strong>Error:</strong> No se pudo obtener respuesta</p>`);
        }

        $chatBox.scrollTop($chatBox[0].scrollHeight);

    } catch (error) {
        console.error('Error:', error);
        // Eliminar indicador de carga en caso de error
        $(`#${loadingId}`).remove();
        $chatBox.append(`<p class="error-message"><strong>Error:</strong> No se pudo conectar con el chatbot</p>`);
        $chatBox.scrollTop($chatBox[0].scrollHeight);
    }
}

$cuadroParaUserInput.on('keypress', function(e) {
    if (e.key === 'Enter') {
        sendMessage();
    }
});

// Mensaje de bienvenida al cargar la página
$(document).ready(function() {
    setTimeout(() => {
        $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ¡Hola! Soy tu asistente de IA. ¿En qué puedo ayudarte hoy?</p>`);
    }, 500);
});