#!/usr/bin/env bash
# TypeScript Project Diagnostic Script
# Analyzes TypeScript projects for configuration, performance, and common issues.

set -euo pipefail

# Check Bash version (requires 4.0+ for associative arrays)
BASH_VERSION_MAJOR="${BASH_VERSINFO[0]}"
if [ "$BASH_VERSION_MAJOR" -lt 4 ]; then
    echo "Error: This script requires Bash 4.0 or higher (current: $BASH_VERSION)"
    echo ""
    echo "macOS users can install Bash 4+ via Homebrew:"
    echo "  brew install bash"
    echo ""
    echo "Then run with: /usr/local/bin/bash $0"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Symbols
CHECK="✅"
WARN="⚠️"
ERROR="❌"
NEUTRAL="⚪"

# Check if jq is available for JSON parsing
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

print_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "----------------------------------------"
}

print_section() {
    echo "=================================================="
    echo "$1"
    echo "=================================================="
}

check_versions() {
    print_header "📦 Versions:"

    # Check TypeScript version
    if command -v npx &> /dev/null; then
        ts_version=$(npx tsc --version 2>/dev/null || echo "Not found")
    else
        ts_version="Not found (npx not available)"
    fi

    # Check Node.js version
    if command -v node &> /dev/null; then
        node_version=$(node -v 2>/dev/null || echo "Not found")
    else
        node_version="Not found"
    fi

    echo "  TypeScript: $ts_version"
    echo "  Node.js: $node_version"
}

check_tsconfig() {
    print_header "⚙️ TSConfig Analysis:"

    if [ ! -f "tsconfig.json" ]; then
        echo "  ${WARN} tsconfig.json not found"
        return
    fi

    if [ "$HAS_JQ" = true ]; then
        # Use jq for proper JSON parsing
        strict=$(jq -r '.compilerOptions.strict // false' tsconfig.json 2>/dev/null)

        if [ "$strict" = "true" ]; then
            echo "  ${CHECK} Strict mode enabled"
        else
            echo "  ${WARN} Strict mode NOT enabled"
        fi

        # Check important flags
        declare -A flags=(
            ["noUncheckedIndexedAccess"]="Unchecked index access protection"
            ["noImplicitOverride"]="Implicit override protection"
            ["skipLibCheck"]="Skip lib check (performance)"
            ["incremental"]="Incremental compilation"
        )

        for flag in "${!flags[@]}"; do
            value=$(jq -r ".compilerOptions.$flag // \"not set\"" tsconfig.json 2>/dev/null)
            if [ "$value" = "true" ]; then
                echo "  ${CHECK} ${flags[$flag]}: $value"
            else
                echo "  ${NEUTRAL} ${flags[$flag]}: $value"
            fi
        done

        # Check module settings
        echo ""
        module=$(jq -r '.compilerOptions.module // "not set"' tsconfig.json 2>/dev/null)
        moduleRes=$(jq -r '.compilerOptions.moduleResolution // "not set"' tsconfig.json 2>/dev/null)
        target=$(jq -r '.compilerOptions.target // "not set"' tsconfig.json 2>/dev/null)

        echo "  Module: $module"
        echo "  Module Resolution: $moduleRes"
        echo "  Target: $target"
    else
        echo "  ${WARN} jq not found - using basic parsing (may be unreliable)"

        if grep -q '"strict"[[:space:]]*:[[:space:]]*true' tsconfig.json 2>/dev/null; then
            echo "  ${CHECK} Strict mode enabled"
        else
            echo "  ${WARN} Strict mode NOT enabled"
        fi

        echo "  ${NEUTRAL} Install jq for detailed analysis (see installation tip below)"
    fi
}

check_tooling() {
    print_header "🛠️ Tooling Detection:"

    if [ ! -f "package.json" ]; then
        echo "  ${WARN} package.json not found"
        return
    fi

    # Tools to check for
    declare -A tools=(
        ["biome"]="Biome (linter/formatter)"
        ["@biomejs"]="Biome (linter/formatter)"
        ["eslint"]="ESLint"
        ["prettier"]="Prettier"
        ["vitest"]="Vitest (testing)"
        ["jest"]="Jest (testing)"
        ["turborepo"]="Turborepo (monorepo)"
        ["turbo"]="Turbo (monorepo)"
        ["@nx/"]="Nx (monorepo)"
        ["nx"]="Nx (monorepo)"
        ["lerna"]="Lerna (monorepo)"
    )

    detected=()
    for tool in "${!tools[@]}"; do
        if grep -q "\"$tool" package.json 2>/dev/null; then
            # Avoid duplicates
            desc="${tools[$tool]}"
            if [[ ! " ${detected[@]} " =~ " ${desc} " ]]; then
                echo "  ${CHECK} $desc"
                detected+=("$desc")
            fi
        fi
    done

    if [ ${#detected[@]} -eq 0 ]; then
        echo "  ${NEUTRAL} No common tooling detected"
    fi
}

check_monorepo() {
    print_header "📦 Monorepo Check:"

    found=false

    [ -f "pnpm-workspace.yaml" ] && echo "  ${CHECK} PNPM Workspace detected" && found=true
    [ -f "lerna.json" ] && echo "  ${CHECK} Lerna detected" && found=true
    [ -f "nx.json" ] && echo "  ${CHECK} Nx detected" && found=true
    [ -f "turbo.json" ] && echo "  ${CHECK} Turborepo detected" && found=true

    if [ "$found" = false ]; then
        echo "  ${NEUTRAL} No monorepo configuration detected"
    fi
}

check_any_usage() {
    print_header "⚠️ 'any' Type Usage:"

    if [ ! -d "src" ]; then
        echo "  ${NEUTRAL} src/ directory not found"
        return
    fi

    count=$(grep -r ': any' --include='*.ts' --include='*.tsx' src/ 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
        echo "  ${WARN} Found $count occurrences of ': any'"
        echo ""
        echo "  Sample (first 5):"
        grep -rn ': any' --include='*.ts' --include='*.tsx' src/ 2>/dev/null | head -5 | sed 's/^/    /'
    else
        echo "  ${CHECK} No explicit 'any' types found"
    fi
}

check_type_assertions() {
    print_header "⚠️ Type Assertions (as):"

    if [ ! -d "src" ]; then
        echo "  ${NEUTRAL} src/ directory not found"
        return
    fi

    count=$(grep -r ' as ' --include='*.ts' --include='*.tsx' src/ 2>/dev/null | \
            grep -v 'import' | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
        echo "  ${WARN} Found $count type assertions"
        echo ""
        echo "  Sample (first 5):"
        grep -rn ' as ' --include='*.ts' --include='*.tsx' src/ 2>/dev/null | \
            grep -v 'import' | head -5 | sed 's/^/    /'
    else
        echo "  ${CHECK} No type assertions found"
    fi
}

check_type_errors() {
    print_header "🔍 Type Check:"

    if ! command -v npx &> /dev/null; then
        echo "  ${WARN} npx not found - cannot run type check"
        return
    fi

    # Run type check and capture output
    output=$(npx tsc --noEmit 2>&1 | head -20)

    if echo "$output" | grep -q "error TS"; then
        error_count=$(echo "$output" | grep -c "error TS" || echo "0")
        echo "  ${ERROR} ${error_count}+ type errors found"
        echo ""
        echo "$output" | head -10 | sed 's/^/    /'
    elif echo "$output" | grep -q "not found"; then
        echo "  ${WARN} TypeScript not found in project"
    else
        echo "  ${CHECK} No type errors"
    fi
}

check_performance() {
    print_header "⏱️ Type Check Performance:"

    if ! command -v npx &> /dev/null; then
        echo "  ${WARN} npx not found - cannot measure performance"
        return
    fi

    # Run with extended diagnostics
    output=$(npx tsc --extendedDiagnostics --noEmit 2>&1 | \
             grep -E 'Check time|Files:|Lines:|Nodes:' || echo "")

    if [ -n "$output" ]; then
        echo "$output" | sed 's/^/  /'
    else
        echo "  ${WARN} Could not measure performance"
    fi
}

check_unused_dependencies() {
    print_header "📦 Dependency Check:"

    if ! command -v npx &> /dev/null || [ ! -f "package.json" ]; then
        echo "  ${NEUTRAL} Cannot check dependencies"
        return
    fi

    # Check if depcheck is available
    if command -v depcheck &> /dev/null || npm list -g depcheck &> /dev/null; then
        echo "  Running depcheck (this may take a moment)..."
        npx --yes depcheck --json 2>/dev/null | head -20 || echo "  ${NEUTRAL} depcheck not available"
    else
        echo "  ${NEUTRAL} Install depcheck for dependency analysis: npm i -g depcheck"
    fi
}

main() {
    print_section "🔍 TypeScript Project Diagnostic Report"

    check_versions
    check_tsconfig
    check_tooling
    check_monorepo
    check_any_usage
    check_type_assertions
    check_type_errors
    check_performance
    check_unused_dependencies

    echo ""
    print_section "✅ Diagnostic Complete"

    if [ "$HAS_JQ" = false ]; then
        echo ""
        echo -e "${YELLOW}💡 Tip: Install jq for better JSON parsing${NC}"
        echo "   macOS: brew install jq"
        echo "   Ubuntu: apt-get install jq"
        echo "   Alpine: apk add jq"
    fi
}

# Run main function
main
