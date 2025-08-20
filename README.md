# Inventory Management

A Swift package for managing inventory with authentication and Supabase integration.

## Requirements

- Swift 5.9+
- iOS 16.0+ / macOS 13.0+

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "YOUR_REPOSITORY_URL", from: "1.0.0")
]
```

## Usage

Documentation coming soon. 



test1
source .env && env SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_KEY="$SUPABASE_SERVICE_KEY" swift test --filter SupabaseClientTests

source .env && env SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_KEY="$SUPABASE_SERVICE_KEY" swift test --filter SupabaseUserServiceTests

source .env && env AUTH0_ISSUER="$AUTH0_ISSUER" swift test --filter Auth0TokenDecoderTests

source .env && env AUTH0_ISSUER="$AUTH0_ISSUER" SUPABASE_URL="$SUPABASE_URL" SUPABASE_SERVICE_KEY="$SUPABASE_SERVICE_KEY" swift test --filter Auth0SupabaseIntegrationTests