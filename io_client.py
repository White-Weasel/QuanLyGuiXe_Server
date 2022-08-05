import websocket


def on_message(ws, message):
    print(message)


def on_error(ws, error):
    print(error)


def on_close(ws, close_status_code, close_msg):
    print("### closed ###")


def on_open(ws):
    print("Opened connection")


if __name__ == "__main__":
    wsapp = websocket.WebSocketApp("http://127.0.0.1:8000", on_message=on_message)
    wsapp.run_forever()
