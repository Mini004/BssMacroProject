const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
    console.log('[TadAlt1] Connected to relay');
    ws.send('REGISTER|Tad Alt 1|Tad');
});

ws.on('message', (data) => {
    const msg = data.toString();
    console.log('[TadAlt1] Received:', msg);

    // Simulate responding to a boost
    if (msg.includes('[BSS_TadSync]') && msg.includes('boosted')) {
        const field = msg.split('|')[2];
        console.log('[TadAlt1] Boost detected! Traveling to:', field);
        ws.send(`[BSS_Status]Tad Alt 1|traveling|${field}`);
    }
});