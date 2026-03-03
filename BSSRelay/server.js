const WebSocket = require('ws');

const PORT = 8080;
const wss = new WebSocket.Server({ port: PORT });

// Track connected clients
const clients = new Map(); // id -> { ws, role, profile }

console.log(`[BSS Relay] Server started on port ${PORT}`);
console.log(`[BSS Relay] Waiting for clients...`);

wss.on('connection', (ws) => {
    let clientID = null;

    ws.on('message', (raw) => {
        const msg = raw.toString().trim();
        
        // ===== REGISTER =====
        // First message must be registration
        // Format: REGISTER|ProfileName|Role
        if (msg.startsWith('REGISTER|')) {
            const parts = msg.split('|');
            clientID = parts[1];       // e.g. "Main", "Tad Alt 1"
            const role = parts[2];     // e.g. "Main", "Tad", "Guide"

            clients.set(clientID, { ws, role, profile: clientID });

            console.log(`[+] Connected: ${clientID} (${role}) | Total: ${clients.size}`);
            ws.send(`ACK|${clientID}|connected`);
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
        }
    });

    ws.on('error', (err) => {
        console.log(`[ERROR] ${clientID}: ${err.message}`);
    });
});