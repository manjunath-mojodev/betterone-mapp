#!/bin/bash
# Generates Secrets.generated.swift from build settings (xcconfig).
# This runs as a Build Phase so the API key never ships in a readable plist.

OUTPUT_FILE="${SRCROOT}/betterone/App/Secrets.generated.swift"

cat > "$OUTPUT_FILE" <<EOF
// Auto-generated at build time — do NOT edit or commit.
import Foundation

enum Secrets {
    static let llmAPIKey = "${LLM_API_KEY}"
    static let revenueCatDevAPIKey = "${REVENUECAT_DEV_API_KEY}"
    static let revenueCatProdAPIKey = "${REVENUECAT_PROD_API_KEY}"

    static var revenueCatAPIKey: String {
        #if DEBUG
        return revenueCatDevAPIKey
        #else
        return revenueCatProdAPIKey
        #endif
    }
}
EOF
