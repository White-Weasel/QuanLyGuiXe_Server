from typing import Optional
from fastapi import Response, status
import psycopg2.errors
from fastapi.responses import HTMLResponse, RedirectResponse
from . import app, db_connect
from .socket import manager
from pydantic import BaseModel
from enum import Enum


@app.get("/")
async def get():
    return RedirectResponse('/docs')


class GateAction(str, Enum):
    open = 'open'
    close = 'close'


class GateControl(BaseModel):
    action: GateAction


class VehicleAction(str, Enum):
    enter = 'in'
    out = 'out'


class ParkingInfo(BaseModel):
    plate: str
    ticket: Optional[int] = None
    action: VehicleAction


@app.post('/gate_control')
async def gate_control(action: GateControl):
    action = action.action.lower() == 'open'
    conn = db_connect()
    cur = conn.cursor()
    cur.execute("INSERT INTO public.gate_log(status) VALUES (%s)", (action,))
    cur.close()
    conn.commit()
    conn.close()

    result = {'gate_status': action}
    await manager.broadcast_json(result)
    return result


@app.post('/parking', status_code=200)
async def parking(info: ParkingInfo, response: Response):
    action = info.action
    result = {}
    print(info)

    conn = db_connect()
    cur = conn.cursor()
    if action == VehicleAction.enter:
        try:
            cur.callproc('vehicle_in', (info.plate, info.ticket))
            result = cur.fetchall()[0][0]
        except psycopg2.errors.CheckViolation as e:
            if "no_dup_active_ticket_check" in e.pgerror:
                response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
                result['result'] = False
                result['err'] = 'Ve xe da ton tai'
    elif action == VehicleAction.out:
        cur.callproc('vehicle_out', (info.plate, info.ticket))
        result = cur.fetchall()[0][0]

    cur.close()
    conn.commit()
    conn.close()

    print(result)
    return result
