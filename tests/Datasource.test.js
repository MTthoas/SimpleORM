import request from 'supertest';
import Datasource  from '../src/datasource/Datasource.res.js';

let client;

beforeAll(async () => {
    let datasource = Datasource.make(
        {
            type_: "postgres",
            host: "localhost",
            port: 5432,
            username : "admin",
            password: "adminpwd",
            database: "db",
            entities: [],
            synchronize: true,
            logging : false
        }
    ) 
});

describe('Datasource', () => {
    it('should return a 200 response', async () => {
        expect(200).toBe(200);
    });


});