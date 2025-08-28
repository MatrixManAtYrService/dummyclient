cmake_minimum_required(VERSION 3.10)
project(dummyclient_demo C)

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
pkg_check_modules(CURL REQUIRED libcurl)

# Collect all the generated source files (exclude our main.c to avoid duplicates)
file(GLOB CLIENT_SOURCES
    ../src/*.c
    ../model/*.c
    ../api/*.c
    ../external/cJSON.c
)
# Remove any main.c from the generated sources to avoid conflicts with our main.c
list(FILTER CLIENT_SOURCES EXCLUDE REGEX "main\\.c$")

# Create the demo executable with all sources compiled directly
add_executable(dummyclient_demo 
    main.c
    ${CLIENT_SOURCES}
)

# Link libraries
target_link_libraries(dummyclient_demo 
    ${CURL_LIBRARIES}
    OpenSSL::SSL 
    OpenSSL::Crypto
)

# Include directories
target_include_directories(dummyclient_demo PRIVATE
    ../include
    ../model
    ../api
    ../external
    ${CURL_INCLUDE_DIRS}
)