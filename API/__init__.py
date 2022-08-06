from fastapi import FastAPI
import psycopg2


def db_connect():
    r"""connect to db using cfg file at C:\Users\admin\AppData\Local\postgres\pg_service.conf"""
    return psycopg2.connect(service='QuanLyGuiXe_Service')


app = FastAPI()

from . import urls
from . import socket
