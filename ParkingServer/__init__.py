from fastapi import FastAPI
import psycopg2


def db_connect():
    r"""connect to db using cfg file at C:\Users\admin\AppData\Local\postgres\pg_service.conf"""
    return psycopg2.connect(service='QuanLyGuiXe_Service')


description = """
API quản lý gửi trả xe bởi Nguyễn Danh Bình Giang - Ltmt1 K11. 🚀

## Socket

Kết nối tới websocket tại endpoint /gate_status.
Gửi chuỗi 'status' tới websocket để lấy trạng thái của cổng. Websocket sẽ trả về json với dạng {'gate_status': <trạng thái của cổng>}
"""

app = FastAPI(title="Parking Manager",
              description=description,
              version="0.0.1", )

from . import urls
from . import socket
