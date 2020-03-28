import logging

from models import Block, Status


class Controller:
    '''
    Класс-контроллер станка
    В нём реализована логика
    '''
    def __init__(self):
        # Исходные настройка станка
        self.status = Status.NO_SETUP
        self.is_auto = False
        self._setup_changed = False
        # Список для хранения очереди блоков для вырезания
        self._queue = []

    def setup(self, x_begin: int, x_end: int, y_begin: int, y_end: int, z_end: int):
        '''
        Метод настройки работы станка, тут формируется очередь обработки блоков
        '''
        self._setup_changed = True

        # Праверка неверных введеных данных
        if x_begin > x_end:
            raise Exception("Wrong arguments! x_begin should be less or equal x_end")
        if y_begin > y_end:
            raise Exception("Wrong arguments! y_begin should be less or equal y_end")
        
        # Цикл формирования очереди
        self._queue = []
        z_begin = 0
        for z in range(z_begin, z_end + 1):
            y_length = y_end - y_begin + 1
            
            y_coords = list(range(y_begin, y_end + 1))
            if z % 2 == 1:
                y_coords = y_coords[::-1]
            
            for y in y_coords:
                x_coords = list(range(x_begin, x_end + 1))
                if (y + z) % 2 == 1:
                    x_coords = x_coords[::-1]
                for x in x_coords:
                    self._queue.append((x, y, z))

        self._queue = [(self._queue[0][0], self._queue[0][1], -1)] + self._queue
        logging.info(f"Setup queue: {self._queue}")


    def get_block(self) -> Block:
        '''
        Функция выдачи блока из очереди
        '''
        logging.info(f"Getting block")

        # Проверка конца работы станка
        if not self._queue:
            self.status = Status.STOPPED
        
        # Создание результата
        x, y, z = self._queue.pop(0)
        block = Block(
            status=self.status,
            isAuto=self.is_auto,
            setupChanged=self._setup_changed,
            x=x, y=y, z=z
        )
        logging.info(f"Send block: {block}")
        self._setup_changed = False
        return block
