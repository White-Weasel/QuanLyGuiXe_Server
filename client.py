import socket

s = socket.socket()
s.connect(('ws://localhost:8000/gate-ctrl', 80))

