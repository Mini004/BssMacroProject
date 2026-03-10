const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

// ===== CONFIG =====
const SERVER_IP = '127.0.0.1';  // Change to main PC's IP on alt PCs
const PORT = 8080;
const OUTBOX = path.join(__dirname, 'outbox.txt');
const INBOX  = path.join(__dirname, 'inbox.txt');

// ===== SETUP FILES =====
if (!fs.existsSync(OUTBOX)) fs.writeFileSync(OUTBOX, '');
if (!fs.existsSync(INBOX))  fs.writeFileSync(INBOX, '');

// ===== OUTBOX POLLER =====
// Started after connection so we don't queue messages before connected
let outboxInterval = null;

function startOutboxPoller(ws) {
    outboxInterval = setInterval(() => {
        try {
            const content = fs.readFileSync(OUTBOX, 'utf8').trim();
            if (content) {
                fs.writeFileSync(OUTBOX, '');
                const lines = content.split('\n').filter(l => l.trim());
                for (const line of lines) {
                    if (ws.readyState === WebSocket.OPEN) {
                        ws.send(line);
                        console.log('[BRIDGE] Sent:', line);
                    }
                }
            }
        } catch (err) {
            // file unavailable, ignore
        }
    }, 100);
}

// ===== AUTO-RECONNECT CONNECT =====
let reconnectDelay = 3000;
let ws = null;

function connect() {
    console.log(`[BRIDGE] Connecting to ws://${SERVER_IP}:${PORT} ...`);
    ws = new WebSocket(`ws://${SERVER_IP}:${PORT}`);

    ws.on('open', () => {
        console.log('[BRIDGE] Connected to relay server');
        reconnectDelay = 3000;   // reset backoff on success
        startOutboxPoller(ws);
    });

    // ===== INCOMING: Relay → INBOX (AHK reads) =====
    ws.on('message', (data) => {
        const msg = data.toString().trim();
        console.log('[BRIDGE] Received:', msg);
        fs.appendFileSync(INBOX, msg + '\n');
    });

    ws.on('close', () => {
        console.log(`[BRIDGE] Disconnected - reconnecting in ${reconnectDelay / 1000}s`);
        if (outboxInterval) {
            clearInterval(outboxInterval);
            outboxInterval = null;
        }
        setTimeout(connect, reconnectDelay);
        reconnectDelay = Math.min(reconnectDelay * 2, 30000);  // exponential backoff, max 30s
    });

    ws.on('error', (err) => {
        // error fires before close; just log, reconnect happens in close handler
        console.log('[BRIDGE] Error:', err.message);
    });
}

connect();
