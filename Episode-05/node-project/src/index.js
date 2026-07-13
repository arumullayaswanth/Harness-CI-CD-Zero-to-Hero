const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'Harness CI/CD - Episode 5: Advanced CI & DevSecOps',
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        status: 'running'
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', uptime: process.uptime() });
});

app.get('/api/users', (req, res) => {
    res.json([
        { id: 1, name: 'Alice', role: 'admin' },
        { id: 2, name: 'Bob', role: 'developer' }
    ]);
});

// Start server
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}

module.exports = app;
