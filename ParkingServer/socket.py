from typing import List

from fastapi import WebSocket, WebSocketDisconnect

from . import app, db_connect


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        print(f"Client {websocket} disconnected")
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast_txt(self, message: str):
        for connection in self.active_connections:
            print(message)
            await connection.send_text(message)

    async def broadcast_json(self, data: dict):
        for connection in self.active_connections:
            await connection.send_json(data)


manager = ConnectionManager()


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("accepted")
    while True:
        data = await websocket.receive_text()
        await websocket.send_text(f"Message text was: {data}")


@app.websocket('/gate_status')
async def gate_status_websocket(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            if data == 'close':
                print("closing socket")
                await websocket.close()
                manager.disconnect(websocket)
                break
            elif data == 'status':
                conn = db_connect()
                cur = conn.cursor()
                cur.callproc('gate_status')
                result = cur.fetchall()[0][0]
                cur.close()
                conn.close()

                await websocket.send_json({'gate_status': result})
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        # await manager.broadcast(f"Client left the chat")
