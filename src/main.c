// Example C application using generated dummyserver client
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// These paths will be available after the client is generated in the nix build
#include "../generated/api/DefaultAPI.h"
#include "../generated/include/apiClient.h"
#include "../generated/model/number_operation.h"
#include "../generated/model/number_response.h"
#include "../generated/model/action_type.h"
#include "../generated/include/list.h"
#include "../generated/external/cJSON.h"

void print_separator() {
    printf("────────────────────────────────────────\n");
}

number_operation_t* create_number_operation(dummy_server_action_type__e action, int value) {
    // Use the generated create function (even though it's deprecated)
    return number_operation_create(action, value);
}

void print_log_entries(list_t *log_entries) {
    if (!log_entries) {
        printf("   No log entries found (NULL response)\n");
        return;
    }
    
    printf("   📋 Operation log (%ld entries):\n", log_entries->count);
    
    if (log_entries->count == 0) {
        printf("   (Log is empty)\n");
        return;
    }
    
    listEntry_t *entry = log_entries->firstEntry;
    int count = 1;
    while (entry && count <= 10) { // Show up to 10 entries
        if (entry->data) {
            cJSON *log_item = (cJSON*)entry->data;
            char *json_string = cJSON_Print(log_item);
            if (json_string) {
                printf("   %d. %s\n", count, json_string);
                free(json_string);
            } else {
                printf("   %d. (Failed to serialize log entry)\n", count);
            }
        } else {
            printf("   %d. (NULL log entry)\n", count);
        }
        entry = entry->nextListEntry;
        count++;
    }
    
    if (log_entries->count > 10) {
        printf("   ... and %ld more entries\n", log_entries->count - 10);
    }
}

int main() {
    printf("🚀 Dummy Server C Client Demo\n");
    printf("============================\n\n");
    
    // Initialize the API client  
    apiClient_t *apiClient = apiClient_create();
    if (!apiClient) {
        fprintf(stderr, "Failed to create API client\n");
        return 1;
    }
    
    // Set the base URL (you can override with DUMMYSERVER_URL env var)
    char *base_url = getenv("DUMMYSERVER_URL");
    if (!base_url) {
        base_url = "http://localhost:8000";
    }
    if (apiClient->basePath) {
        free(apiClient->basePath);
    }
    apiClient->basePath = strdup(base_url);
    
    printf("📡 Connecting to: %s\n", base_url);
    print_separator();
    
    // 1. Get the initial number
    printf("1️⃣  Getting initial number...\n");
    number_response_t *current_response = DefaultAPI_getNumberNumberGet(apiClient);
    
    if (!current_response) {
        printf("   ❌ Failed to get current number. Is the server running?\n");
        printf("   💡 Try: nix run ../dummyserver\n\n");
        apiClient_free(apiClient);
        return 1;
    }
    
    int initial_number = current_response->number;
    printf("   ✅ Initial number: %d\n", initial_number);
    number_response_free(current_response);
    print_separator();
    
    // 2. Add 25 to the number
    printf("2️⃣  Adding 25 to the number...\n");
    number_operation_t *add_op = create_number_operation(dummy_server_action_type__add, 25);
    if (!add_op) {
        printf("   ❌ Failed to create add operation\n");
        apiClient_free(apiClient);
        return 1;
    }
    
    
    number_response_t *add_response = DefaultAPI_modifyNumberNumberPost(apiClient, add_op);
    if (add_response) {
        printf("   ✅ After adding 25: %d -> %d\n", initial_number, add_response->number);
        number_response_free(add_response);
    } else {
        printf("   ❌ Failed to add 25 to the number\n");
    }
    
    number_operation_free(add_op);
    print_separator();
    
    // 3. Subtract 10 from the number
    printf("3️⃣  Subtracting 10 from the number...\n");
    number_operation_t *subtract_op = create_number_operation(dummy_server_action_type__subtract, 10);
    if (!subtract_op) {
        printf("   ❌ Failed to create subtract operation\n");
        apiClient_free(apiClient);
        return 1;
    }
    
    number_response_t *subtract_response = DefaultAPI_modifyNumberNumberPost(apiClient, subtract_op);
    if (subtract_response) {
        printf("   ✅ After subtracting 10: %d\n", subtract_response->number);
        number_response_free(subtract_response);
    } else {
        printf("   ❌ Failed to subtract 10 from the number\n");
    }
    
    number_operation_free(subtract_op);
    print_separator();
    
    // 4. Get the final number to confirm
    printf("4️⃣  Getting final number...\n");
    number_response_t *final_response = DefaultAPI_getNumberNumberGet(apiClient);
    if (final_response) {
        printf("   ✅ Final number: %d\n", final_response->number);
        printf("   🧮 Expected: %d + 25 - 10 = %d\n", initial_number, initial_number + 25 - 10);
        
        if (final_response->number == initial_number + 25 - 10) {
            printf("   ✅ Math checks out!\n");
        } else {
            printf("   ⚠️  Unexpected result\n");
        }
        
        number_response_free(final_response);
    } else {
        printf("   ❌ Failed to get final number\n");
    }
    print_separator();
    
    // 5. Get operation log
    printf("5️⃣  Getting operation log...\n");
    list_t *log_response = DefaultAPI_getLogLogGet(apiClient);
    if (log_response) {
        printf("   ✅ Got log response successfully\n");
        print_log_entries(log_response);
        // Note: Free the list - this should handle cleanup properly
        list_freeList(log_response);
    } else {
        printf("   ❌ Failed to get operation log\n");
    }
    print_separator();
    
    apiClient_free(apiClient);
    
    printf("✨ Demo completed!\n");
    printf("\n🎯 This demo shows advanced OpenAPI client features:\n");
    printf("   ✅ GET requests - fetching data\n");
    printf("   ✅ POST requests - sending structured data\n");
    printf("   ✅ Complex data types - enums and structs\n");
    printf("   ✅ JSON parsing - automatic serialization\n");
    printf("   ✅ Error handling - robust API interactions\n");
    printf("   ✅ Memory management - proper cleanup\n");
    printf("\n💡 Generated from dummy.openapi.json with zero manual HTTP code!\n");
    
    return 0;
}