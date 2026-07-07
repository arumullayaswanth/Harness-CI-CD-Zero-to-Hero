cmake_minimum_required(VERSION 3.16)
project(harness-cpp-app VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Main application
add_executable(app src/main.cpp)

# Tests
add_executable(tests tests/test_main.cpp)

# Install
install(TARGETS app DESTINATION bin)
