from WorkerPosition import WorkerPosition
from DBConnection import DBConnection, sql, Error


class IBaseWorkerPositionRep(DBConnection):
    def GetAll(self) -> dict:
        records = self.Execute(query='SELECT * FROM worker_position ORDER BY id', mode='All')
        if not isinstance(records, list):
            return records

        positions = dict()
        for record in records:
            positions[record[0]] = WorkerPosition(id=record[0], pos=record[1])

        return positions

    def GetById(self, wp_id: int) -> WorkerPosition:
        get_query = sql.SQL('SELECT * FROM worker_position WHERE id = {}').format(
            sql.Literal(wp_id))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return WorkerPosition(id=record[0], pos=record[1])

    def Append(self, o_position: str) -> WorkerPosition:
        append_query = sql.SQL('INSERT INTO worker_position(position) VALUES ({}) RETURNING id;').format(
            sql.Literal(o_position))
        wp_id = self.Execute(query=append_query, mode='One')
        if not isinstance(wp_id, tuple):
            return wp_id

        return WorkerPosition(id=wp_id[0], pos=o_position)

    def Delete(self, work_pos_object: WorkerPosition) -> int:
        delete_query = sql.SQL('DELETE FROM worker_position WHERE id = {};').format(
            sql.Literal(work_pos_object.id))
        return self.Execute(query=delete_query)

    def Update(self, work_pos_object: WorkerPosition) -> int:
        update_query = sql.SQL('UPDATE worker_position SET position = {} WHERE id = {};').format(
            sql.Literal(work_pos_object.position),
            sql.Literal(work_pos_object.id))
        return self.Execute(query=update_query)
