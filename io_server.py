from fastapi import FastAPI
from fastapi_socketio import SocketManager
import uvicorn

app = FastAPI()
sio = SocketManager(app=app)


@app.sio.on('join')
async def handle_join(sid, *args, **kwargs):
    await sio.emit('lobby', 'User joined')


@sio.on('test')
async def test(sid, *args, **kwargs):
    await sio.emit('hey', 'joe')


if __name__ == '__main__':
    uvicorn.run("io_server:app", host='0.0.0.0', port=8000, reload=True, debug=False)
