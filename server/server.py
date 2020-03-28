from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from controller import Controller
from models import Block, Status


app = FastAPI()
controller = Controller()

origins = [
    "http://localhost",
    "http://localhost:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root() -> str:
    return "Pilorezka 😈"


@app.get("/setup")
def read_setup(xBegin: int, xEnd: int, yBegin: int, yEnd: int, zEnd: int):
    '''
    параметры паза [200 OK, если begin <= end, 
    begin и end меньше либо равны габаритам куба. 
    Иначе 422 Unprocessable Entity]
    '''
    try:
        controller.setup(xBegin, xEnd, yBegin, yEnd, zEnd)
    except Exception as e:
        raise HTTPException(
            status_code=422, detail=str(e),
            headers={"X-Error": str(e)}
        )


@app.get("/start")
def read_start():
    '''
    [200 OK] – кнопка «Пуск», меняет status на ‘work’
    '''
    controller.status = Status.WORK


@app.get("/pause")
def read_pause():
    '''
    [200 OK] – кнопка «СТОП», меняет status на ‘pause’
    '''
    controller.status = Status.PAUSE


@app.get("/stop")
def read_stop():
    '''
    [200 OK] – кнопка «Конец работы», меняет status на ‘stopped’
    '''
    controller.status = Status.STOPPED


@app.get("/auto")
def read_auto(timeMs: int):
    '''
    [200 OK] – кнопка «Автоматический режим», меняет isAuto на true
    '''
    controller.is_auto = True
    controller.sleep_time = timeMs


@app.get("/manual")
def read_manual():
    '''
    [200 OK] - кнопка «Ручной режим», меняет isAuto на fals
    '''
    controller.is_auto = False


@app.get("/block")
def read_block() -> Block:
    '''
    [200 OK] – возвращает JSON типа
    '''
    try:
        return controller.get_block()
    except Exception as e:
        raise HTTPException(
            status_code=422, detail=str(e),
            headers={"X-Error": str(e)}
        )
