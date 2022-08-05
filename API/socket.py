from . import socket_manager as sio


@sio.on('connect')
async def handle_new_connect(sid, *args, **kwargs):
    await sio.emit('client_data', sid)
