import datetime
from typing import Optional
from fastapi import Response, status
import psycopg2.errors
import psycopg2.extras
from fastapi.responses import HTMLResponse, RedirectResponse
from . import app, db_connect
from .socket import manager
from pydantic import BaseModel
from enum import Enum
from utls import replace_last


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
    time_in: Optional[datetime.datetime] = None
    time_out: Optional[datetime.datetime] = None
    vehivle_type: Optional[int] = 1
    face: Optional[str] = None


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


@app.post('/parking')
async def parking(info: ParkingInfo, response: Response):
    action = info.action
    result = {}
    print(info)
    """
    if len(info.plate) < 1:
        response.status_code = status.HTTP_400_BAD_REQUEST
        result['result'] = False
        result['err'] = f'Bien so rong!'
        return result
    if info.action == VehicleAction.out and info.ticket is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        result['result'] = False
        result['err'] = f'Ve xe rong!'
        return result
    """
    conn = db_connect()
    cur = conn.cursor()
    if action == VehicleAction.enter:
        try:
            cur.callproc('vehicle_in', (info.plate, info.ticket))
            result = cur.fetchall()[0][0]
        except psycopg2.errors.UniqueViolation as e:
            response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
            result['result'] = False
            err_mess = e.pgerror
            if "unique_active_plate_constaint" in err_mess:
                result['err'] = f'Xe {info.plate} da o trong bai'
            elif "unique_active_ticket_constaint" in err_mess:
                result['err'] = f'Ve xe dang duoc su dung'
            elif 'unique_active_ticket_plate_constaint' in err_mess:
                result['err'] = f'Ve xe va xe dang trong bai'
            else:
                raise e
    elif action == VehicleAction.out:
        cur.callproc('vehicle_out', (info.plate, info.ticket))
        result = cur.fetchall()[0][0]

    cur.close()
    conn.commit()
    conn.close()

    print(result)
    return result


@app.get('/parking_search')
def parking_search(response: Response,
                   plate: Optional[str] = None,
                   ticket: Optional[int] = None,
                   time_in: Optional[datetime.datetime] = None,
                   inside: Optional[bool] = None,
                   vehivle_type: Optional[int] = None,
                   face: Optional[str] = None
                   ):
    params = {
        'plate': plate,
        'ticket': ticket,
        'time_in': time_in,
        'inside': inside,
        'vehivle_type': vehivle_type,
        'face': face,
    }
    params = {k: v for k, v in params.items() if v is not None}
    result = {'result': False}
    if len(params) > 0:
        sql = f"Select * from parking where "
        data = []
        for key, value in params.items():
            sql += f'{key}=%s AND '
            data.append(value)
        sql = replace_last(sql, 'AND', '')
        print(sql)

        conn = db_connect()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql, data)
        result['data'] = cur.fetchall()
        result['result'] = True
        cur.close()
        conn.close()
    else:
        response.status_code = status.HTTP_400_BAD_REQUEST
        result['err'] = 'Thong tin rong!'

    return result
