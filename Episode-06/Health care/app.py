"""
Healthcare Website Backend - Episode 6
Flask serves the static HTML + provides API endpoints
"""

from flask import Flask, send_from_directory, jsonify
import os

app = Flask(__name__, static_folder='.', static_url_path='')


@app.route('/')
def index():
    return send_from_directory('.', 'index.html')


@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "healthcare-website"})


@app.route('/api/doctors')
def doctors():
    return jsonify([
        {"id": 1, "name": "Dr. Soni Bharti", "specialization": "Cardiologist"},
        {"id": 2, "name": "Dr. Paresh Rawal", "specialization": "Neurosurgeon"},
        {"id": 3, "name": "Dr. Munna Bhai", "specialization": "Dermatologist"}
    ])


@app.route('/api/services')
def services():
    return jsonify([
        {"id": 1, "name": "Laboratory Test", "description": "Accurate Diagnostics"},
        {"id": 2, "name": "Health Check", "description": "Thorough Assessments"},
        {"id": 3, "name": "General Dentistry", "description": "Comprehensive Oral Care"}
    ])


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
