import websocket
from websocket import create_connection

ws = create_connection("ws://127.0.0.1:8000/gate_status")

ws.send("status")
result = ws.recv()
print(f"Received {result}")

ws.send('close')
#ws.close()
