const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
    console.log('[TEST] Connected to relay');
    
    // Register as Main
    ws.send('REGISTER|Main|Main');
    
    // After 1 second, send a test boost message
    setTimeout(() => {
        ws.send('[BSS_TadSync]Main|boosted|pinetree');
        console.log('[TEST] Sent boost message');
    }, 1000);
});

ws.on('message', (data) => {
    console.log('[TEST] Received:', data.toString());
});

ws.on('close', () => {
    console.log('[TEST] Disconnected');
});