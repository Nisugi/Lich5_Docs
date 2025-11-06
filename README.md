# Lich5 Documentation Automation

Automated YARD documentation generation for the Lich5 Ruby scripting framework using AI (primarily Google Gemini's free tier).

## Features

- **Multi-provider support**: Gemini (free), OpenAI, or Mock for testing
- **Smart chunking**: Handles large Ruby files by splitting at logical boundaries
- **GitHub Actions automation**: Manual trigger with optional update monitoring
- **Cost-conscious**: Optimized for Gemini's free tier (1500 requests/day)
- **YARD-compatible**: Generates standard Ruby documentation format

## Quick Start

### 1. Clone & Install

```bash
git clone https://github.com/yourusername/lich5-docs-auto.git
cd lich5-docs-auto
pip install -r requirements.txt
```

### 2. Get API Key (Free)

Get a **free** Google Gemini API key:
1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy your key

### 3. Configure

```bash
# Copy example config
cp .env.example .env

# Edit .env and add your Gemini API key
GEMINI_API_KEY=your_key_here
```

### 4. Test

```bash
# Test with mock provider (no API needed)
python test_provider.py --provider mock

# Test with Gemini
python test_provider.py --provider gemini --file tests/samples/version.rb
```

### 5. Generate Documentation

```bash
# Document a single file
python generate_docs.py path/to/file.rb

# Document entire directory
python generate_docs.py path/to/lich/src/lib --yard

# Use mock provider for testing
python generate_docs.py tests/samples --provider mock
```

## Providers

| Provider | Cost | Rate Limits | Use Case |
|----------|------|-------------|----------|
| **Gemini** | FREE | 15/min, 1500/day | Primary provider (recommended) |
| **OpenAI** | ~$0.50-2/run | Pay per use | If Gemini quality insufficient |
| **Mock** | FREE | None | Testing pipeline without API calls |

## GitHub Actions Workflows

### Manual Documentation Generation

Trigger documentation generation on-demand:

```yaml
# .github/workflows/manual-docs.yml
- Choose provider (gemini/openai/mock)
- Select source repository and branch
- Creates PR with updated documentation
```

### Update Monitoring

Weekly check for new Lich releases:

```yaml
# .github/workflows/check-updates.yml
- Runs Monday 3 AM UTC
- Creates issue if new release found
- Does NOT auto-generate (requires manual trigger)
```

## Project Structure

```
lich5-docs-auto/
├── src/
│   ├── providers/          # LLM provider implementations
│   │   ├── base.py        # Abstract base class
│   │   ├── gemini.py      # Google Gemini (free tier)
│   │   ├── openai_provider.py  # OpenAI fallback
│   │   ├── mock.py        # Testing provider
│   │   └── factory.py     # Provider selection
│   └── utils/             # Helper functions
├── .github/
│   └── workflows/         # GitHub Actions
│       ├── manual-docs.yml     # Manual trigger
│       └── check-updates.yml   # Monitor for updates
├── tests/
│   └── samples/           # Sample Ruby files for testing
├── generate_docs.py       # Main documentation generator
├── test_provider.py       # Provider quality testing
└── requirements.txt       # Python dependencies
```

## Configuration

### Environment Variables

```bash
# Provider selection
LLM_PROVIDER=gemini  # or openai, mock

# API Keys (only set what you need)
GEMINI_API_KEY=your_gemini_key
OPENAI_API_KEY=your_openai_key  # Optional

# Repository settings
LICH_REPO_OWNER=elanthia-online
LICH_REPO_NAME=lich-5
```

### Cost Management

**Gemini Free Tier Limits:**
- 15 requests per minute
- 1500 requests per day
- ~50-100 files per day depending on size

The generator will:
- Warn when approaching limits
- Estimate if job can complete
- Suggest splitting large jobs

## Command Line Usage

### Test Provider Quality

```bash
# Test single provider
python test_provider.py --provider gemini --file path/to/file.rb

# Test all providers
python test_provider.py --all-providers --file tests/samples/version.rb
```

### Generate Documentation

```bash
# Basic usage
python generate_docs.py input_directory

# With options
python generate_docs.py input_directory \
  --provider gemini \
  --output output/custom \
  --pattern "*.rb" \
  --yard
```

### Options

- `--provider`: Choose LLM provider (gemini/openai/mock)
- `--output`: Output directory (default: output/{timestamp})
- `--pattern`: File pattern to match (default: *.rb)
- `--yard`: Generate YARD comment files

## GitHub Actions Setup

### 1. Add Secrets

In your GitHub repository settings:

1. Go to Settings → Secrets → Actions
2. Add `GEMINI_API_KEY` with your API key
3. (Optional) Add `OPENAI_API_KEY` if using OpenAI

### 2. Run Manual Workflow

1. Go to Actions tab
2. Select "Manual Documentation Generation"
3. Click "Run workflow"
4. Choose options and run

### 3. Monitor Updates

The check-updates workflow runs automatically weekly, or trigger manually from Actions tab.

## Transfer to Elanthia Online

See [transfer/SETUP.md](transfer/SETUP.md) for instructions on transferring this repository to the Elanthia Online organization.

## Troubleshooting

### "Module not found" errors

```bash
# Install missing dependencies
pip install google-generativeai python-dotenv
```

### Rate limit errors

- Wait until the next day (quotas reset daily)
- Split large jobs across multiple days
- Consider OpenAI if you have credits

### Unicode errors on Windows

The code has been updated to avoid emoji characters that cause encoding issues.

### API key not found

Make sure your `.env` file exists and contains:
```
GEMINI_API_KEY=your_actual_key_here
```

## Development

### Running Tests

```bash
# Test with mock provider (no API needed)
python test_provider.py --provider mock

# Test documentation generation
python generate_docs.py tests/samples --provider mock
```

### Adding New Providers

1. Create new provider in `src/providers/`
2. Inherit from `LLMProvider` base class
3. Implement `generate()` method
4. Add to factory.py

## License

This project is designed to document the Lich5 project. Please respect the original Lich5 license and attribution requirements.

## Support

- Issues: Create an issue in this repository
- Lich5 Project: https://github.com/elanthia-online/lich-5

---

**Note:** This tool requires an API key for Gemini (free) or OpenAI (paid). The mock provider can be used for testing without any API keys.