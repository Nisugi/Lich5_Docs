# Lich 5 Documentation Generator

Automated YARD documentation generation for the [Lich 5](https://github.com/elanthia-online/lich-5) Ruby scripting engine using AI (OpenAI, Anthropic, or Gemini).

**📖 [View Documentation Website](https://nisugi.github.io/lich-5-docs/)**

## Overview

This project uses AI to automatically generate comprehensive YARD documentation for the Lich 5 Ruby codebase. The system processes 120 Ruby files, adding professional documentation comments that enable:

- ✅ **120/120 files** with complete YARD documentation
- 📚 **1,805 methods** documented with parameters, return types, and examples
- 🔗 **Cross-references** between classes and modules
- 🌐 **Searchable HTML website** hosted on GitHub Pages
- ⚡ **Incremental builds** that only reprocess changed files

## Features

### 🤖 AI-Powered Documentation
- Supports **OpenAI GPT-4**, **Anthropic Claude**, and **Google Gemini**
- Generates YARD-compliant comments with `@param`, `@return`, `@example` tags
- Preserves existing documentation (never overwrites manual edits)

### ⚡ Intelligent Incremental Builds
- **SHA256 hash tracking** detects changed files
- Only reprocesses files that have been modified
- Saves time and API costs (~$0.50 → $0.00 for unchanged codebases)

### 📋 Modular 3-Stage Workflow
```
Generate → Validate → Build HTML
```
Each stage is manually triggered, giving full control over the documentation process.

### 🎯 100% Validation Success
- All generated documentation passes YARD validation
- Automatically fixes common issues (parameter syntax, duplicate tags)
- Clean, professional output ready for publication

## Quick Start

### Prerequisites

- Python 3.11+
- Ruby 3.0+ with YARD gem
- API key for OpenAI, Anthropic, or Gemini

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nisugi/lich-5-docs.git
   cd lich-5-docs
   ```

2. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Install YARD**
   ```bash
   gem install yard
   ```

4. **Configure API key**
   ```bash
   cp .env.example .env
   # Edit .env and add your API key
   ```

### Usage

#### Generate Documentation

```bash
# Incremental build (skip unchanged files)
python generate_docs.py /path/to/lich-5/lib \
  --provider openai \
  --output-structure mirror

# Full rebuild (reprocess all files)
python generate_docs.py /path/to/lich-5/lib \
  --provider openai \
  --output-structure mirror \
  --force-rebuild

# Single file (for testing)
python generate_docs.py \
  --file /path/to/lich-5/lib/gemstone/psms/feat.rb \
  --provider openai \
  --output-structure mirror
```

#### Validate Documentation

```bash
# Validate all files
python validate_docs.py --dir documented

# Validate single file
python validate_docs.py --file documented/global_defs.rb
```

#### Build HTML Documentation

```bash
# Generate HTML website
python build_html.py --input ./documented --output ./docs --clean
```

## GitHub Actions Workflows

The project includes 4 GitHub Actions workflows for automated documentation:

### 1. Generate Batch Documentation
**Path:** `.github/workflows/generate-batch.yml`

Generates documentation for all Ruby files from the lich-5 repository.

**Inputs:**
- `provider`: LLM provider (openai, anthropic, gemini)
- `source_repo`: Source repository (default: `elanthia-online/lich-5`)
- `source_branch`: Branch to document (default: `main`)
- `full_rebuild`: Force reprocess all files (default: `false`)

### 2. Generate Single File
**Path:** `.github/workflows/generate-single.yml`

Fast iteration on a single file for testing and debugging.

### 3. Validate Documentation
**Path:** `.github/workflows/validate-docs.yml`

Validates all documented files using YARD.

### 4. Build HTML
**Path:** `.github/workflows/build-html.yml`

Generates the static HTML documentation website.

**Inputs:**
- `title`: Documentation title (default: "Lich 5 Documentation")
- `clean`: Clean output directory before building (default: `true`)

## Project Structure

```
lich-5-docs/
├── documented/              # YARD-documented Ruby files (mirrors lich-5/lib structure)
│   ├── common/
│   ├── gemstone/
│   ├── attributes/
│   └── ...
├── docs/                    # Generated HTML documentation (GitHub Pages)
├── output/latest/           # Build artifacts
│   └── manifest.json        # Incremental build tracking
├── src/providers/           # LLM provider implementations
│   ├── openai_provider.py
│   ├── anthropic_provider.py
│   └── gemini.py
├── generate_docs.py         # Main documentation generator
├── validate_docs.py         # YARD validation wrapper
└── build_html.py            # HTML documentation builder
```

## How It Works

### 1. Generation
- Clones the lich-5 repository
- Processes each Ruby file with AI to generate YARD comments
- Returns structured JSON: `[{line_number, anchor, indent, comment}, ...]`
- Inserts comments at the correct positions in the source code
- Commits documented files to the `documented/` directory

### 2. Incremental Builds
- Calculates SHA256 hash of each file (code only, excluding comments)
- Compares with hashes in `manifest.json`
- Skips files that haven't changed
- Only reprocesses modified files

### 3. Validation
- Runs `yard stats --list-undoc` on all documented files
- Parses warnings and errors
- Reports validation success rate

### 4. HTML Generation
- Runs `yard doc` to generate static HTML website
- Verifies output (checks for index.html, counts documented items)
- Commits to `docs/` directory
- GitHub Pages automatically deploys the website

## Configuration

### Environment Variables

```bash
# LLM Provider (openai, anthropic, gemini)
LLM_PROVIDER=openai

# API Keys (only one required based on provider)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...
```

### Provider Options

The system supports three LLM providers:

- **OpenAI**: Uses `gpt-4o-mini` model (paid, see [OpenAI pricing](https://openai.com/api/pricing/))
- **Anthropic**: Uses `claude-3-haiku-20240307` model (paid, see [Anthropic pricing](https://www.anthropic.com/pricing))
- **Gemini**: Uses `gemini-2.0-flash-exp` model (free tier available, see [Google AI pricing](https://ai.google.dev/pricing))

For current pricing and rate limits, consult the provider's official documentation.

## Development

### Running Tests

```bash
pytest tests/
```

### Testing Without API Costs

```bash
# Use mock provider (no API calls)
python generate_docs.py /path/to/source --provider mock
```

### Checking Provider Status

```python
from providers import ProviderFactory

validation = ProviderFactory.validate_environment()
print(validation)  # Shows provider, API key status, warnings
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Detailed technical documentation for developers
- **[.env.example](.env.example)** - Environment variable template
- **[Generated Documentation](https://nisugi.github.io/lich-5-docs/)** - Live documentation website

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is independent of the Lich 5 project and is used for documentation purposes.

## Acknowledgments

- **Lich 5** - [elanthia-online/lich-5](https://github.com/elanthia-online/lich-5)
- **YARD** - Ruby documentation tool
- **OpenAI, Anthropic, Google** - AI providers for documentation generation

---

**Built with ❤️ using AI-powered documentation generation**
