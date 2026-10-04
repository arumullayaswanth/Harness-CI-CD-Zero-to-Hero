// Tests run with no FME SDK key, so the SDK is not ready → treatment "control"
// → banner OFF (safe default). This runs in CI.
const request = require("supertest");
const app = require("./app");

describe("FME Feature Flags demo app", () => {
    it("GET / renders the store page (banner OFF by default)", async () => {
        const res = await request(app).get("/");
        expect(res.statusCode).toBe(200);
        expect(res.text).toContain("Online Store");
        expect(res.text).toContain("new_checkout_banner treatment");
    });

    it("GET /health returns healthy", async () => {
        const res = await request(app).get("/health");
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe("healthy");
    });
});
