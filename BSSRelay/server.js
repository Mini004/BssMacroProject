const WebSocket = require('ws');

const PORT = 8080;
const wss = new WebSocket.Server({ port: PORT });

// Track connected clients: id -> { ws, role }
const clients = new Map();

console.log(`[BSS Relay] Server started on port ${PORT}`);
console.log(`[BSS Relay] Waiting for clients...`);

wss.on('connection', (ws) => {
    let clientID = null;
    let clientRole = 'unknown';

    ws.on('message', (raw) => {
        const msg = raw.toString().trim();

        // ===== REGISTER =====
        // Format: REGISTER|ClientName|Role
        if (msg.startsWith('REGISTER|')) {
            const parts = msg.split('|');
            clientID   =
             parts[1];
            clientRole = parts[2] || 'unknown';

            clients.set(clientID, { ws, role: clientRole });

            console.log(`[+] Connected: ${clientID} (${clientRole}) | Total: ${clients.size}`);
            ws.send(`ACK|${clientID}|connected`);

            // Notify all other connected clients
            for (const [id, client] of clients) {
                if (id !== clientID && client.ws.readyState === WebSocket.OPEN) {
                    client.ws.send(`[BSS_NOTIFY]Server|CLIENT_JOINED|${clientID}:${clientRole}`);
                }
            }
            return;
        }

        // ===== RELAY MESSAGE =====
        // Format: [CODEWORD]Sender|command|data
        if (msg.startsWith('[BSS_')) {
            console.log(`[RELAY] ${msg}`);

            // Broadcast to all OTHER clients
            for (const [id, client] of clients) {
                if (id !== clientID && client.ws.readyState === WebSocket.OPEN) {
                    client.ws.send(msg);
                }
            }
            return;
        }

        console.log(`[?] Unknown message from ${clientID}: ${msg}`);
    });

    ws.on('close', () => {
        if (clientID) {
            clients.delete(clientID);
            console.log(`[-] Disconnected: ${clientID} | Total: ${clients.size}`);

            // Notify remaining clients
            for (const [id, client] of clients) {
                if (client.ws.readyState === WebSocket.OPEN) {
                    client.ws.send(`[BSS_NOTIFY]Server|CLIENT_LEFT|${clientID}:${clientRole}`);
                }
            }
        }
    });

    ws.on('error', (err) => {
        console.log(`[ERROR] ${clientID}: ${err.message}`);
    });
});
