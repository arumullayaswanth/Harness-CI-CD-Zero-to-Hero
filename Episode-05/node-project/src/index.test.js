const request = require('supertest');
const app = require('./index');

describe('App Endpoints', () => {
    test('GET / returns app info', async () => {
        const res = await request(app).get('/');
        expect(res.statusCode).toBe(200);
        expect(res.body.message).toContain('Episode 5');
        expect(res.body.status).toBe('running');
    });

    test('GET /health returns healthy', async () => {
        const res = await request(app).get('/health');
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe('healthy');
    });

    test('GET /api/users returns users', async () => {
        const res = await request(app).get('/api/users');
        expect(res.statusCode).toBe(200);
        expect(res.body.length).toBe(2);
        expect(res.body[0].name).toBe('Alice');
    });
});
