// Unit tests — these run in the CI pipeline on every Pull Request.
// This is what proves "Code Review + CI gate" before merge.
const request = require("supertest");
const app = require("./app");

describe("Harness Code Repo demo API", () => {
    it("GET / returns welcome message", async () => {
        const res = await request(app).get("/");
        expect(res.statusCode).toBe(200);
        expect(res.body.episode).toBe(11);
    });

    it("GET /health returns healthy", async () => {
        const res = await request(app).get("/health");
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe("healthy");
    });

    it("GET /version returns a version", async () => {
        const res = await request(app).get("/version");
        expect(res.statusCode).toBe(200);
        expect(res.body.version).toBeDefined();
    });
});
