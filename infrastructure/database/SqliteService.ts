// infrastructure/database/SQLiteService.ts
import SQLite from 'react-native-sqlite-storage';

export class SQLiteService {
  private db: SQLite.SQLiteDatabase;

  constructor() {
    this.db = SQLite.openDatabase(
      { name: 'app.db', location: 'default' },
      () => console.log('Database opened'),
      err => console.log('DB error: ', err)
    );
  }

  init() {
    this.db.transaction(tx => {
      tx.executeSql(
        'CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT);'
      );
    });
  }

  getNotes(): Promise<string[]> {
    return new Promise((resolve, reject) => {
      this.db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM notes;',
          [],
          (_, results) => {
            const rows = results.rows;
            const notes = [];
            for (let i = 0; i < rows.length; i++) {
              notes.push(rows.item(i).content);
            }
            resolve(notes);
          },
          (_, error) => {
            reject(error);
            return false;
          }
        );
      });
    });
  }

  addNote(content: string): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.transaction(tx => {
        tx.executeSql(
          'INSERT INTO notes (content) VALUES (?);',
          [content],
          () => resolve(),
          (_, error) => {
            reject(error);
            return false;
          }
        );
      });
    });
  }
}
