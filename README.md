<img 
  src="https://github.com/user-attachments/assets/e603c5ca-0683-4005-96d4-e5737d43d06e"
  width="100%"
/>

# Nadeef

A command-line tool that scans an iOS / macOS project and reports unused (unreferenced) Swift types — classes, structs, enums, protocols, actors, and extensions.

## Install

Clone the repo, build in release mode, and drop the binary on your `PATH`:

```bash
git clone https://github.com/MazenBaddad/Nadeef.git
cd Nadeef
swift build --configuration release
cp -f .build/release/nadeef /usr/local/bin/nadeef
```

To update later, pull and rebuild:

```bash
git pull && swift build -c release && cp -f .build/release/nadeef /usr/local/bin/nadeef
```

## Usage

Scan the current directory:

```bash
nadeef swift
```

Scan a specific path:

```bash
nadeef swift path/to/your-project
```

Protect known entry-point types so they aren't flagged:

```bash
nadeef swift --roots AppDelegate --roots ":XCTestCase" --roots "*_Previews"
```

Root patterns:

- `"Name"` — exact match
- `"pre*"` — starts with `pre`
- `"*suffix"` — ends with `suffix`
- `"*text*"` — contains `text`
- `":Parent"` — inherits from or conforms to `Parent`
- `":*Parent"` — inherits from or conforms to any type ending with `Parent`

### Example output

```
Nadeef scan
  files scanned  : 42
  objects found  : 128
  unused objects : 2

Unused objects:
  - LegacyHelper (class)
      Sources/Helpers/LegacyHelper.swift
  - UnusedModel (struct)
      Sources/Models/UnusedModel.swift
      Sources/Models/UnusedModel+Codable.swift
```

Each listed object is followed by the path of every file where it is defined (the primary declaration plus any extensions in other files).

## Options

| Flag | Purpose |
| --- | --- |
| `--roots <pattern>` | Mark entry-point types so they are never reported as unused. May be repeated. |
| `--format human\|json\|sarif` | Output format written to **stdout**. Default: `human`. |
| `--output-json <path>` | Also write a JSON report to the given file. |
| `--output-sarif <path>` | Also write a SARIF 2.1.0 report to the given file. |
| `--project-root <path>` | Base directory used to make file paths relative in JSON/SARIF. Defaults to the search path. |
| `--log-level debug\|info\|warn\|error\|quiet` | Diagnostic verbosity on **stderr**. Default: `warn`. |
| `--fail-on-findings` | Exit with status `1` when unused objects are found. |

Machine output (the selected `--format`) goes to **stdout**; diagnostics go to **stderr**, so `nadeef swift . --format json > report.json` works without log noise in the file.

Exit codes:

- `0` — clean run (or findings reported but `--fail-on-findings` not set)
- `1` — unused objects found and `--fail-on-findings` was set
- `2` — tool error (invalid input, I/O failure, etc.)

### JSON output

```json
{
  "version": "1",
  "tool": "nadeef",
  "toolVersion": "0.3.0",
  "generatedAt": "2026-04-21T12:34:56Z",
  "summary": { "totalFiles": 42, "totalObjects": 128, "unusedCount": 1 },
  "unused": [
    {
      "name": "Foo",
      "kind": "class",
      "paths": ["Sources/Foo.swift", "Sources/Foo+Extra.swift"]
    }
  ]
}
```

`paths` contains every file where the object is defined (primary declaration plus any extensions), de-duplicated and in discovery order. Paths are relative to `--project-root`.

### SARIF output

Standard SARIF 2.1.0 — each unused object becomes a `warning`-level result with one `location` per defining file. Useful for any tool that speaks SARIF (GitHub code scanning, VS Code's SARIF viewer, etc.).

## Licence

See [LICENSE](LICENSE).
