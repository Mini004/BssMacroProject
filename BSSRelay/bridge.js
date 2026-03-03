const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

// ===== CONFIG =====
const SERVER_IP = '127.0.0.1';  // Change if server is on different PC
const PORT = 8080;
const OUTBOX = path.join(__dirname, 'outbox.txt');
const INBOX  = path.join(__dirname, 'inbox.txt');

// ===== SETUP FILES =====
if (!fs.existsSync(OUTBOX)) fs.writeFileSync(OUTBOX, '');
if (!fs.existsSync(INBOX))  fs.writeFileSync(INBOX, '');

// ===== CONNECT TO RELAY =====
const ws = new WebSocket(`ws://${SERVER_IP}:${PORT}`);

ws.on('open', () => {
    console.log('[BRIDGE] Connected to relay server');
    // AHK will send REGISTER as first message via outbox
});

// ===== INCOMING: Relay → INBOX (AHK reads) =====
ws.on('message', (data) => {
    const msg = data.toString().trim();
    console.log('[BRIDGE] Received:', msg);
    
    // Append to inbox for AHK to read
    fs.appendFileSync(INBOX, msg + '\n');
});

ws.on('close', () => {
    console.log('[BRIDGE] Disconnected from relay');
});

ws.on('error', (err) => {
    console.log('[BRIDGE] Error:', err.message);
});

// ===== OUTGOING: OUTBOX (AHK writes) → Relay =====
let lastOutbox = '';

setInterval(() => {
    try {
        const content = fs.readFileSync(OUTBOX, 'utf8').trim();
        
        if (content) {
            // Clear outbox FIRST before sending
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
        // File doesn't exist yet, ignore
    }
}, 100);