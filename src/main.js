let rootElement = EMBED.getRootElement();
let data = EMBED.getComponent().schema.data;

export const $API_GATEWAY_URL = data.API_GATEWAY_URL.manual;
export const $API_GATEWAY_API_KEY = data.API_GATEWAY_API_KEY.manual;
export const $SYSTEM_DATA =  EMBED.getGlobalData(data.SYSTEM_DATA);
export const USER_NAME =  EMBED.getGlobalData(data.USER_NAME);

const chatbot_endpoint = $API_GATEWAY_URL.endsWith('/chat') ?
    $API_GATEWAY_URL :
    `${$API_GATEWAY_URL}/chat`;

// Datos del sistema (JSON con información sobre tramos, presión, linepack, autonomía)
// Este JSON será enviado como contexto con cada prompt pero no será visible para el usuario
// const $SYSTEM_DATA = {
//     "timestamp": new Date().toISOString(),
//     "pipeline_segments": [
//         {
//             "id": "037-001",
//             "name": "Sistema Tandil - MDP",
//             "pressure": {
//                 "upstream": 45.2,
//                 "downstream": 38.7,
//                 "average": 41.95,
//                 "threshold": {
//                     "critical": 35.0,
//                     "warning": 40.0
//                 }
//             },
//             "linepack": 8.72,
//             "flow_rate": 2.3,
//             "autonomy": 3.79,
//             "status": "warning"
//         },
//         {
//             "id": "036-026",
//             "name": "Sistema de la Costa",
//             "pressure": {
//                 "upstream": 56.4,
//                 "downstream": 51.2,
//                 "average": 53.8,
//                 "threshold": {
//                     "critical": 35.0,
//                     "warning": 40.0
//                 }
//             },
//             "linepack": 12.45,
//             "flow_rate": 1.8,
//             "autonomy": 6.92,
//             "status": "optimal"
//         },
//         {
//             "id": "037-091",
//             "name": "Sistema Balcarce",
//             "pressure": {
//                 "upstream": 32.1,
//                 "downstream": 28.5,
//                 "average": 30.3,
//                 "threshold": {
//                     "critical": 35.0,
//                     "warning": 40.0
//                 }
//             },
//             "linepack": 6.21,
//             "flow_rate": 2.1,
//             "autonomy": 2.96,
//             "status": "critical"
//         },
//         {
//             "id": "036-032",
//             "name": "Sistema MDP Ciudad",
//             "pressure": {
//                 "upstream": 42.3,
//                 "downstream": 39.8,
//                 "average": 41.05,
//                 "threshold": {
//                     "critical": 35.0,
//                     "warning": 40.0
//                 }
//             },
//             "linepack": 9.34,
//             "flow_rate": 3.2,
//             "autonomy": 2.92,
//             "status": "warning"
//         }
//     ],
//     "system_summary": {
//         "total_segments": 4,
//         "critical_segments": 1,
//         "warning_segments": 2,
//         "optimal_segments": 1,
//         "average_system_pressure": 41.78,
//         "total_linepack": 36.72,
//         "lowest_autonomy": 2.92,
//         "highest_autonomy": 6.92
//     }
// };

// jQuery selectors
const $cuadroParaUserInput = $('#cuadroParaUserInput');
const $chatBox = $('#chat-box');
const $sendButton = $('#sendButton');
const $quickQuestionBtns = $('.quick-question-btn');

// Agregar evento para los botones de navegación
$('.navButton').on('click', function () {
    if ($(this).text().includes('Map View')) {
        EMBED.executeAction("onClickedMapViewButton");
    }
});

// Agregar evento click para el botón de envío
$sendButton.on('click', function () {
    sendMessage();
});

// Agregar eventos para los botones de preguntas rápidas
$quickQuestionBtns.on('click', function () {
    const question = $(this).text().trim();
    $cuadroParaUserInput.val(question);
    sendMessage();

    // Efecto de feedback visual en el botón
    $(this).css('background-color', 'var(--primary-color)');
    $(this).css('color', 'var(--panel-background)');

    setTimeout(() => {
        $(this).css('background-color', '');
        $(this).css('color', '');
    }, 500);
});

// Función para crear el prompt completo incluyendo el contexto de datos
function createPromptWithContext(userQuery) {
    // Instrucciones para el modelo sobre cómo usar los datos
    const instructions = `
Eres un asistente especializado en sistemas industriales de transporte de gas natural. 
A continuación te proporciono datos del sistema actual en formato JSON. 
Usa estos datos para responder a la consulta del usuario de forma precisa, 
mencionando valores específicos cuando sea relevante.

DATOS DEL SISTEMA:
${JSON.stringify($SYSTEM_DATA, null, 2)}

CONSULTA DEL USUARIO:
${userQuery}
`;

    return instructions;
}

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

    // Crear el prompt completo con el contexto de datos
    const promptWithContext = createPromptWithContext(textoDelUsuario);

    try {
        const response = await fetch(chatbot_endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": $API_GATEWAY_API_KEY
            },
            body: JSON.stringify({ query: promptWithContext })
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

$cuadroParaUserInput.on('keypress', function (e) {
    if (e.key === 'Enter') {
        sendMessage();
    }
});

// Función para actualizar los datos del sistema (podría conectarse a una API)
function updateSystemData(newData) {
    // Actualizamos solo las partes proporcionadas en newData
    if (newData.pipeline_segments) {
        $SYSTEM_DATA.pipeline_segments = newData.pipeline_segments;
    }

    if (newData.system_summary) {
        $SYSTEM_DATA.system_summary = newData.system_summary;
    }

    // Actualizamos el timestamp
    $SYSTEM_DATA.timestamp = new Date().toISOString();

    console.log("Datos del sistema actualizados:", $SYSTEM_DATA);
}

// Exponer la función de actualización globalmente para posibles actualizaciones desde otros componentes
window.updateBotSystemData = updateSystemData;

// Mensaje de bienvenida al cargar la página
$(document).ready(function () {
    setTimeout(() => {
        $chatBox.append(`<p class="bot-message"><strong>Camu Bot:</strong> ¡Hola! ${USER_NAME} Soy tu asistente de IA, ¿en qué puedo ayudarte hoy?</p>`);
    }, 500);
});