from fastapi.responses import HTMLResponse, RedirectResponse
from . import app


@app.get("/")
async def get():
    return RedirectResponse('/docs')
