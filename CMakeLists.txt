cmake_minimum_required(VERSION 3.16)
project(DummyClient)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(Boost REQUIRED COMPONENTS system thread filesystem chrono atomic)
find_package(OpenSSL REQUIRED)
find_package(nlohmann_json REQUIRED)

# Find cpprestsdk using pkg-config
pkg_check_modules(CPPREST REQUIRED cpprestsdk)

# Include generated client
add_subdirectory(generated)

# Main application
add_executable(dummy_client src/main.cpp)

target_link_libraries(dummy_client 
    PRIVATE 
    DummyServerClient
    ${Boost_LIBRARIES}
    OpenSSL::SSL 
    OpenSSL::Crypto
    nlohmann_json::nlohmann_json
    ${CPPREST_LIBRARIES}
)

target_include_directories(dummy_client 
    PRIVATE 
    generated/include
    ${Boost_INCLUDE_DIRS}
    ${CPPREST_INCLUDE_DIRS}
)

target_compile_options(dummy_client PRIVATE ${CPPREST_CFLAGS_OTHER})