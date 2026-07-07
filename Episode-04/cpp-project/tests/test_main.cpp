#include <iostream>
#include <cassert>
#include <string>

// Include the functions we're testing
const std::string APP_NAME = "Harness CI/CD Course";
const std::string VERSION = "1.0.0";
const int EPISODE = 4;
const std::string LANGUAGE = "C++";

std::string getJsonResponse() {
    std::ostringstream json;
    json << "{";
    json << "\"message\":\"Hello from " << APP_NAME << "!\",";
    json << "\"episode\":" << EPISODE << ",";
    json << "\"version\":\"" << VERSION << "\",";
    json << "\"language\":\"" << LANGUAGE << "\",";
    json << "\"status\":\"running\"";
    json << "}";
    return json.str();
}

std::string getHealthResponse() {
    return "{\"status\":\"healthy\"}";
}

void test_json_response() {
    std::string response = getJsonResponse();
    assert(response.find("Hello from Harness CI/CD Course!") != std::string::npos);
    assert(response.find("\"episode\":4") != std::string::npos);
    assert(response.find("\"language\":\"C++\"") != std::string::npos);
    assert(response.find("\"status\":\"running\"") != std::string::npos);
    std::cout << "✅ test_json_response PASSED" << std::endl;
}

void test_health_response() {
    std::string response = getHealthResponse();
    assert(response == "{\"status\":\"healthy\"}");
    std::cout << "✅ test_health_response PASSED" << std::endl;
}

void test_version() {
    assert(VERSION == "1.0.0");
    assert(EPISODE == 4);
    assert(LANGUAGE == "C++");
    std::cout << "✅ test_version PASSED" << std::endl;
}

int main() {
    std::cout << "=== Running Unit Tests ===" << std::endl;
    test_json_response();
    test_health_response();
    test_version();
    std::cout << "=== All Tests Passed! ===" << std::endl;
    return 0;
}
