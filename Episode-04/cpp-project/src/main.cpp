#include <iostream>
#include <string>
#include <cstdlib>
#include <sstream>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <cstring>

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

std::string handleRequest(const std::string& request) {
    std::string response_body;
    std::string content_type = "application/json";

    if (request.find("GET /health") != std::string::npos) {
        response_body = getHealthResponse();
    } else if (request.find("GET /") != std::string::npos) {
        response_body = getJsonResponse();
    } else {
        response_body = "{\"error\":\"not found\"}";
    }

    std::ostringstream response;
    response << "HTTP/1.1 200 OK\r\n";
    response << "Content-Type: " << content_type << "\r\n";
    response << "Content-Length: " << response_body.size() << "\r\n";
    response << "\r\n";
    response << response_body;
    return response.str();
}

int main() {
    int port = 8080;
    const char* env_port = std::getenv("PORT");
    if (env_port) port = std::atoi(env_port);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        std::cerr << "Failed to create socket" << std::endl;
        return 1;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        std::cerr << "Failed to bind to port " << port << std::endl;
        return 1;
    }

    if (listen(server_fd, 10) < 0) {
        std::cerr << "Failed to listen" << std::endl;
        return 1;
    }

    std::cout << "Server starting on port " << port << std::endl;

    while (true) {
        int client_fd = accept(server_fd, nullptr, nullptr);
        if (client_fd < 0) continue;

        char buffer[4096] = {0};
        read(client_fd, buffer, sizeof(buffer));

        std::string request(buffer);
        std::string response = handleRequest(request);

        write(client_fd, response.c_str(), response.size());
        close(client_fd);
    }

    close(server_fd);
    return 0;
}
