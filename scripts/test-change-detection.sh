#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# Test script for change detection logic
# Simulates what the GitHub Actions workflow does
# ─────────────────────────────────────────────────────────────────

PRODUCTS_DIR="products"

echo "=========================================="
echo "STM32 Monorepo Change Detection Test"
echo "=========================================="

run_test() {
    local test_name="$1"
    local changed_files="$2"
    
    echo ""
    echo "──────────────────────────────────────────"
    echo "TEST: $test_name"
    echo "──────────────────────────────────────────"
    echo "Changed files:"
    echo "$changed_files" | sed 's/^/  - /'
    echo ""
    
    # Auto-discover product folders
    ALL_PRODUCTS=""
    if [ -d "$PRODUCTS_DIR" ]; then
        ALL_PRODUCTS=$(ls -d $PRODUCTS_DIR/*/ 2>/dev/null | while read d; do basename "$d"; done | sort)
    fi
    
    # Match changed files to product folders
    CHANGED_PRODUCTS=""
    for product in $ALL_PRODUCTS; do
        if echo "$changed_files" | grep -q "^${PRODUCTS_DIR}/${product}/"; then
            [ -n "$CHANGED_PRODUCTS" ] && CHANGED_PRODUCTS="$CHANGED_PRODUCTS,$product" || CHANGED_PRODUCTS="$product"
        fi
    done
    
    HAS_PRODUCT_CHANGES="false"
    NON_PRODUCT_ONLY="false"
    [ -n "$CHANGED_PRODUCTS" ] && HAS_PRODUCT_CHANGES="true"
    
    # Check for non-product changes
    HAS_NON_PRODUCT=$(echo "$changed_files" | grep -v "^${PRODUCTS_DIR}/" | head -1)
    [ -n "$HAS_NON_PRODUCT" ] && [ "$HAS_PRODUCT_CHANGES" = "false" ] && NON_PRODUCT_ONLY="true"
    
    # Build JSON array
    if [ -n "$CHANGED_PRODUCTS" ]; then
        PRODUCTS_JSON=$(echo "$CHANGED_PRODUCTS" | tr ',' '\n' | while read p; do echo "\"$p\""; done | paste -sd, - | sed 's/^/[/;s/$/]/')
    else
        PRODUCTS_JSON='[]'
    fi
    
    echo "Results:"
    echo "  has_product_changes: $HAS_PRODUCT_CHANGES"
    echo "  non_product_only:    $NON_PRODUCT_ONLY"
    echo "  changed_products:    $PRODUCTS_JSON"
    
    # Determine action
    if [ "$HAS_PRODUCT_CHANGES" = "true" ]; then
        echo "  ACTION: ✅ AUTO DEPLOY - $CHANGED_PRODUCTS"
    elif [ "$NON_PRODUCT_ONLY" = "true" ]; then
        echo "  ACTION: ⚠️  MANUAL DEPLOY REQUIRED"
    else
        echo "  ACTION: ⏭️  SKIP - No relevant changes"
    fi
}

# Test 1: Single product change
run_test "single_product" "products/FLO/app/main.c"

# Test 2: Multiple products changed
run_test "multiple_products" "products/FLO/app/main.c
products/TIM/app/main.c"

# Test 3: Product + common (should auto-deploy product only)
run_test "product_and_common" "products/ONE/lora/app_version.h
common/board/inc/board_config.h"

# Test 4: Common/SDK only (manual deploy)
run_test "common_only" "common/drivers/spi_flash.c
sdk/Drivers/hal_driver.c"

# Test 5: Docs only (manual deploy)
run_test "docs_only" "README.md
docs/JIRA-TICKET.md"

# Test 6: Mixed - products + common + docs
run_test "mixed_all" "products/FLO/app/main.c
products/TIM+/lora/app_version.h
common/board/inc/board_config.h
README.md"

# Test 7: FSO product (new product)
run_test "new_product_fso" "products/FSO/lora/app_version.h"

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="
