# TypeScript Expert Skill

Comprehensive TypeScript development skill with references, utilities, and diagnostic tools.

## Structure

```
typescript/
├── SKILL.md                           # Main skill documentation
├── README.md                          # This file
├── references/                        # Reference materials
│   ├── tsconfig-strict.json          # Strict TypeScript configuration template
│   ├── utility-types.ts              # Reusable utility types library
│   └── typescript-cheatsheet.md      # Quick reference guide
└── scripts/                           # Diagnostic and helper scripts
    └── ts_diagnostic.sh              # Project diagnostic tool
```

## Using the Skill

This skill provides expert-level TypeScript guidance including:

- Core principles and best practices
- Advanced type system patterns
- Real-world problem resolution
- Performance optimization
- Modern tooling decisions
- Migration strategies
- Debugging techniques

## Reference Files

### tsconfig-strict.json

A production-ready, strict TypeScript configuration template with:
- Maximum type safety enabled
- Modern ESM module system
- Performance optimizations
- Sensible defaults

Copy this file to your project and adjust as needed:
```bash
cp references/tsconfig-strict.json ./tsconfig.json
```

### utility-types.ts

A comprehensive library of reusable utility types including:
- **Branded types** - Domain modeling with nominal types
- **Result/Option types** - Type-safe error handling
- **Deep utilities** - DeepReadonly, DeepPartial, DeepRequired, DeepMutable
- **Object utilities** - PickByType, PartialBy, RequiredBy, Merge
- **Array utilities** - NonEmptyArray, Tuple, AtLeast
- **Function utilities** - AsyncFunction, Promisify
- **String utilities** - Split, Join, PathOf
- **Union utilities** - UnionToIntersection, UnionToTuple
- **Validation utilities** - AssertEqual, IsNever, IsAny
- **JSON utilities** - Jsonify, JsonValue
- **Exhaustive checks** - assertNever, exhaustiveCheck

Copy types you need into your project:
```typescript
import type { Brand, Result, DeepReadonly } from './utility-types'
```

### typescript-cheatsheet.md

Quick reference guide with examples for:
- Type basics
- Interfaces and type aliases
- Generics
- Utility types
- Conditional types
- Template literals
- Mapped types
- Type guards
- Discriminated unions
- Branded types
- Module declarations
- TSConfig essentials
- Best practices

## Diagnostic Script

### ts_diagnostic.sh

**Pure Bash implementation** - works without any dependencies!

Analyzes TypeScript projects for configuration, performance, and common issues.

**Features:**
- ✅ No dependencies required (works with just Bash)
- ✅ Optional jq support for enhanced JSON parsing
- ✅ Colored output for better readability
- Checks TypeScript and Node versions
- Analyzes tsconfig.json settings
- Detects tooling ecosystem (Biome, ESLint, Vitest, etc.)
- Checks for monorepo configuration
- Scans for 'any' type usage
- Identifies type assertions with code samples
- Runs type checking
- Measures type check performance

**Usage:**
```bash
# From project root
./path/to/skills/typescript/scripts/ts_diagnostic.sh

# Or copy to your project
cp scripts/ts_diagnostic.sh .
chmod +x ts_diagnostic.sh
./ts_diagnostic.sh
```

**Requirements:**
- Bash 4.0+ (required)
  - Most modern Linux distributions ship with Bash 4.0+ by default
  - macOS ships with Bash 3.2; install newer Bash via: `brew install bash`
- Optional: `jq` for enhanced JSON parsing
  - macOS: `brew install jq`
  - Ubuntu: `apt-get install jq`
  - Alpine: `apk add jq`

**Example Output:**
```
==================================================
🔍 TypeScript Project Diagnostic Report
==================================================

📦 Versions:
----------------------------------------
  TypeScript: Version 5.3.3
  Node.js: v20.10.0

⚙️ TSConfig Analysis:
----------------------------------------
✅ Strict mode enabled
  ✅ Unchecked index access protection: True
  ✅ Implicit override protection: True
  ✅ Skip lib check (performance): True
  ✅ Incremental compilation: True

  Module: ESNext
  Module Resolution: bundler
  Target: ES2022

🛠️ Tooling Detection:
----------------------------------------
  ✅ Biome (linter/formatter)
  ✅ Vitest (testing)

📦 Monorepo Check:
----------------------------------------
  ⚪ No monorepo configuration detected

⚠️ 'any' Type Usage:
----------------------------------------
  ✅ No explicit 'any' types found

⚠️ Type Assertions (as):
----------------------------------------
  ⚠️ Found 12 type assertions

🔍 Type Check:
----------------------------------------
  ✅ No type errors

⏱️ Type Check Performance:
----------------------------------------
  Check time: 2.5s
  Files: 245
  Lines: 45,123
  Nodes: 189,456

==================================================
✅ Diagnostic Complete
==================================================
```

## Tips

### Quick Wins
1. Copy `tsconfig-strict.json` for instant strict mode setup
2. Use utility types from `utility-types.ts` to avoid reinventing patterns
3. Keep `typescript-cheatsheet.md` handy for quick lookups
4. Run `ts_diagnostic.sh` to identify issues in your project

### Common Patterns
- Use branded types for domain primitives (IDs, emails, etc.)
- Use Result/Option types for type-safe error handling
- Use discriminated unions for state machines
- Use mapped types for transforming object shapes
- Use template literals for string pattern matching

### Performance Tips
- Enable `skipLibCheck: true`
- Use `incremental: true` compilation
- Configure `include`/`exclude` precisely
- Use project references for monorepos
- Avoid deeply nested conditional types

## Contributing

Found a useful pattern or utility? Consider adding it to:
- `utility-types.ts` - For reusable type utilities
- `typescript-cheatsheet.md` - For quick reference examples
- `ts_diagnostic.sh` - For additional diagnostic checks
