#!/usr/bin/env python3
"""
Test script to evaluate LLM provider quality
Run this to test documentation generation on sample files
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import argparse
import logging
from pathlib import Path
from providers import get_provider, ProviderFactory

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def create_documentation_prompt(file_name: str, content: str) -> tuple[str, str]:
    """
    Create prompts for documentation generation

    Returns:
        (system_prompt, user_prompt) tuple
    """
    system_prompt = """You are an expert Ruby documentation specialist.
Your task is to generate YARD-compatible documentation for Ruby code.
Focus on clarity, completeness, and following YARD conventions."""

    user_prompt = f"""Analyze this Ruby file from the Lich5 project: **{file_name}**

```ruby
{content}
```

Generate **YARD-compatible** documentation for every public class, module, method, and constant.

Rules for each method/class/module:
• Include these tags whenever applicable:
  - @param - list every parameter with type and description
  - @return - state return type and meaning
  - @raise - describe possible exceptions
  - @example - provide a concise usage example
  - @note - mention any caveats or side effects

• Place comment blocks immediately above the element they document
• Use proper indentation matching the code
• Be concise but thorough

Return ONLY the documentation comments in YARD format, without the Ruby code.

Example format:
```ruby
# Description of the class/module
#
# @example
#   MyClass.new.my_method
class MyClass

  # Description of method
  #
  # @param arg1 [String] description of arg1
  # @return [Boolean] what it returns
  # @example
  #   my_method("test")
  def my_method(arg1)
```"""

    return system_prompt, user_prompt


def test_provider(provider_name: str, test_file: str):
    """
    Test a provider on a sample file

    Args:
        provider_name: Provider to test ('gemini', 'openai', 'mock')
        test_file: Path to Ruby file to test
    """
    # Validate environment first
    validation = ProviderFactory.validate_environment(provider_name)
    if not validation['valid']:
        logger.error(f"Environment validation failed: {validation}")
        if validation['missing']:
            logger.error(f"Missing environment variables: {', '.join(validation['missing'])}")
        return False

    # Show warnings
    for warning in validation.get('warnings', []):
        logger.warning(warning)

    # Load test file
    test_path = Path(test_file)
    if not test_path.exists():
        logger.error(f"Test file not found: {test_file}")
        return False

    logger.info(f"Testing {provider_name} on {test_path.name}")

    with open(test_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Show file stats
    lines = len(content.split('\n'))
    chars = len(content)
    logger.info(f"File stats: {lines} lines, {chars} characters")

    # Create provider
    try:
        provider = get_provider(provider_name)
    except Exception as e:
        logger.error(f"Failed to create provider: {e}")
        return False

    # Generate documentation
    system_prompt, user_prompt = create_documentation_prompt(test_path.name, content)

    try:
        logger.info("Generating documentation...")
        result = provider.generate(user_prompt, system_prompt)

        # Save result
        output_dir = Path('test_output')
        output_dir.mkdir(exist_ok=True)
        output_file = output_dir / f"{test_path.stem}_{provider_name}_docs.rb"

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(result)

        logger.info(f"[SUCCESS] Documentation generated successfully!")
        logger.info(f"Output saved to: {output_file}")
        logger.info(f"Output size: {len(result)} characters")

        # Show provider stats
        stats = provider.get_stats()
        logger.info(f"Provider stats: {stats}")

        # Show a snippet of the output
        print("\n" + "="*60)
        print("GENERATED DOCUMENTATION (first 500 chars):")
        print("="*60)
        print(result[:500])
        print("..." if len(result) > 500 else "")
        print("="*60 + "\n")

        return True

    except Exception as e:
        logger.error(f"Documentation generation failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='Test LLM provider quality')
    parser.add_argument(
        '--provider',
        choices=['gemini', 'openai', 'mock'],
        default='gemini',
        help='Provider to test (default: gemini)'
    )
    parser.add_argument(
        '--file',
        default='tests/samples/version.rb',
        help='Ruby file to test (default: tests/samples/version.rb)'
    )
    parser.add_argument(
        '--all-providers',
        action='store_true',
        help='Test all available providers'
    )

    args = parser.parse_args()

    # Show provider info
    info = ProviderFactory.get_provider_info()
    print("\n" + "="*60)
    print("AVAILABLE PROVIDERS:")
    print("="*60)
    for name, details in info['available_providers'].items():
        recommended = "[RECOMMENDED]" if details.get('recommended') else ""
        print(f"\n{name}: {details['description']} {recommended}")
        print(f"  Cost: {details['cost']}")
        print(f"  Limits: {details['limits']}")
        if details.get('note'):
            print(f"  Note: {details['note']}")
    print("="*60 + "\n")

    if args.all_providers:
        # Test all providers
        providers = ['mock', 'gemini', 'openai']
        for provider in providers:
            print(f"\n[TEST] Testing {provider}...")
            success = test_provider(provider, args.file)
            if not success and provider == 'openai':
                print("Note: OpenAI test failed - likely no API key set (expected)")
    else:
        # Test single provider
        test_provider(args.provider, args.file)


if __name__ == '__main__':
    main()