from enum import Enum

from pydantic import BaseModel


class Status(Enum):
    NO_SETUP = "noSetup"
    PAUSE = "pause"
    WORK = "work"
    STOPPED = "stopped"


class Block(BaseModel):
    status: Status
    isAuto: bool
    setupChanged: bool
    x: int
    y: int
    z: int
