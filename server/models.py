from enum import Enum

from pydantic import BaseModel


class Status(Enum):
    NO_SETUP = "noSetup"
    PAUSE = "pause"
    WORK = "work"
    STOPPED = "stopped"


class Block(BaseModel):
    status: Status  # Статус работы станка
    isAuto: bool  # Режим работы 
    setupChanged: bool  # Флаг изменения настроек
    x: int # Координата x
    y: int # Координата y
    z: int # Координата z
