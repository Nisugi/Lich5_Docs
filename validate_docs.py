#!/usr/bin/env python3
"""
YARD Documentation Validator

Validates YARD documentation in Ruby files without generating HTML.
Can validate a single file or the entire documented/ directory.

Usage:
    python validate_docs.py                    # Validate all files in documented/
    python validate_docs.py --file feat.rb     # Validate specific file
    python validate_docs.py --strict           # Exit with error code if YARD warnings found

Exit Codes:
    0 - Success (even with warnings, unless --strict is used)
    1 - Error (file not found, YARD not installed, or --strict with warnings)
"""

import argparse
import subprocess
import sys
from pathlib import Path
import re
from typing import List, Dict, Tuple
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class YARDValidator:
    def __init__(self, documented_dir: Path = None, strict: bool = False):
        """
        Initialize YARD validator.

        Args:
            documented_dir: Path to documented files directory
            strict: If True, exit with error code if warnings found
        """
        self.documented_dir = documented_dir or Path(__file__).parent / "output" / "latest" / "documented"
        self.strict = strict

    def check_yard_installed(self) -> bool:
        """Check if YARD is installed and available."""
        try:
            result = subprocess.run(
                ['yard', '--version'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                logger.info(f"YARD version: {result.stdout.strip()}")
                return True
            else:
                logger.error("YARD command failed")
                return False
        except FileNotFoundError:
            logger.error("YARD is not installed. Install with: gem install yard")
            return False
        except subprocess.TimeoutExpired:
            logger.error("YARD version check timed out")
            return False

    def find_file(self, filename: str) -> Path:
        """
        Find a Ruby file in the documented directory.

        Args:
            filename: Filename to search for (e.g., 'feat.rb')

        Returns:
            Path to the file if found

        Raises:
            FileNotFoundError: If file not found
        """
        # Search recursively in documented directory
        matches = list(self.documented_dir.rglob(filename))

        if not matches:
            raise FileNotFoundError(f"File '{filename}' not found in {self.documented_dir}")

        if len(matches) > 1:
            logger.warning(f"Multiple matches found for '{filename}':")
            for match in matches:
                logger.warning(f"  - {match}")
            logger.info(f"Using: {matches[0]}")

        return matches[0]

    def parse_yard_output(self, output: str) -> Dict[str, List[str]]:
        """
        Parse YARD output into structured format.

        Args:
            output: Raw YARD stderr output

        Returns:
            Dictionary with error types as keys and list of error messages as values
        """
        errors = {
            'syntax_errors': [],
            'unhandled_exceptions': [],
            'warnings': [],
            'other': []
        }

        lines = output.split('\n')
        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Categorize errors
            if '[error]:' in line.lower():
                if 'syntax error' in line.lower():
                    errors['syntax_errors'].append(line)
                else:
                    errors['other'].append(line)
            elif 'unhandled exception' in line.lower():
                errors['unhandled_exceptions'].append(line)
            elif '[warn]:' in line.lower() or 'warning' in line.lower():
                errors['warnings'].append(line)
            elif any(indicator in line for indicator in ['error', 'failed', 'invalid']):
                errors['other'].append(line)

        return errors

    def validate_file(self, file_path: Path) -> Tuple[bool, Dict[str, List[str]]]:
        """
        Validate a single Ruby file with YARD.

        Args:
            file_path: Path to Ruby file to validate

        Returns:
            Tuple of (success, errors_dict)
        """
        if not file_path.exists():
            logger.error(f"File not found: {file_path}")
            return False, {'other': [f"File not found: {file_path}"]}

        logger.info(f"Validating: {file_path}")

        try:
            # Run YARD in stats mode (doesn't generate HTML, just checks documentation)
            result = subprocess.run(
                ['yard', 'stats', '--list-undoc', str(file_path)],
                capture_output=True,
                text=True,
                timeout=30
            )

            # Parse both stdout and stderr
            combined_output = result.stdout + "\n" + result.stderr
            errors = self.parse_yard_output(combined_output)

            # Count total issues
            total_issues = sum(len(issues) for issues in errors.values())

            if total_issues == 0:
                logger.info(f"✓ {file_path.name} - No issues found")
                return True, errors
            else:
                logger.warning(f"⚠ {file_path.name} - {total_issues} issues found")
                return True, errors  # Still return True unless strict mode

        except subprocess.TimeoutExpired:
            logger.error(f"YARD validation timed out for {file_path}")
            return False, {'other': ['Validation timed out']}
        except Exception as e:
            logger.error(f"Error validating {file_path}: {e}")
            return False, {'other': [str(e)]}

    def validate_directory(self) -> Tuple[bool, Dict[str, Dict[str, List[str]]]]:
        """
        Validate all Ruby files in documented directory.

        Returns:
            Tuple of (success, results_dict) where results_dict maps filenames to error dicts
        """
        if not self.documented_dir.exists():
            logger.error(f"Documented directory not found: {self.documented_dir}")
            return False, {}

        ruby_files = list(self.documented_dir.rglob("*.rb"))

        if not ruby_files:
            logger.warning(f"No Ruby files found in {self.documented_dir}")
            return True, {}

        logger.info(f"Found {len(ruby_files)} Ruby files to validate")

        results = {}
        all_success = True

        for file_path in sorted(ruby_files):
            success, errors = self.validate_file(file_path)
            if not success:
                all_success = False

            # Store results with relative path as key
            rel_path = file_path.relative_to(self.documented_dir)
            results[str(rel_path)] = errors

        return all_success, results

    def print_summary(self, results: Dict[str, Dict[str, List[str]]]):
        """Print summary of validation results."""
        print("\n" + "="*80)
        print("VALIDATION SUMMARY")
        print("="*80)

        total_files = len(results)
        files_with_issues = sum(1 for errors in results.values() if any(errors.values()))

        print(f"\nTotal files validated: {total_files}")
        print(f"Files with issues: {files_with_issues}")
        print(f"Files clean: {total_files - files_with_issues}")

        if files_with_issues > 0:
            print("\n" + "-"*80)
            print("FILES WITH ISSUES:")
            print("-"*80)

            for filename, errors in results.items():
                total_issues = sum(len(issues) for issues in errors.values())
                if total_issues > 0:
                    print(f"\n{filename}: {total_issues} issues")

                    for error_type, messages in errors.items():
                        if messages:
                            print(f"  {error_type.replace('_', ' ').title()}: {len(messages)}")
                            for msg in messages[:3]:  # Show first 3 of each type
                                print(f"    - {msg[:100]}")
                            if len(messages) > 3:
                                print(f"    ... and {len(messages) - 3} more")


def main():
    parser = argparse.ArgumentParser(
        description='Validate YARD documentation in Ruby files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python validate_docs.py                       # Validate all files
  python validate_docs.py --file feat.rb        # Validate specific file
  python validate_docs.py --strict              # Exit with error if warnings found
  python validate_docs.py --dir ./documented    # Validate custom directory
        """
    )

    parser.add_argument(
        '--file',
        help='Validate a specific file (searches in documented directory)'
    )

    parser.add_argument(
        '--dir',
        help='Path to documented files directory (default: output/latest/documented)'
    )

    parser.add_argument(
        '--strict',
        action='store_true',
        help='Exit with error code if any warnings found'
    )

    args = parser.parse_args()

    # Initialize validator
    documented_dir = Path(args.dir) if args.dir else None
    validator = YARDValidator(documented_dir=documented_dir, strict=args.strict)

    # Check YARD installation
    if not validator.check_yard_installed():
        sys.exit(1)

    # Validate single file or directory
    if args.file:
        try:
            file_path = validator.find_file(args.file)
            success, errors = validator.validate_file(file_path)

            # Print detailed errors
            total_issues = sum(len(issues) for issues in errors.values())
            if total_issues > 0:
                print("\n" + "="*80)
                print(f"Issues found in {file_path.name}:")
                print("="*80)
                for error_type, messages in errors.items():
                    if messages:
                        print(f"\n{error_type.replace('_', ' ').title()}:")
                        for msg in messages:
                            print(f"  - {msg}")

            if args.strict and total_issues > 0:
                logger.error(f"Validation failed in strict mode: {total_issues} issues found")
                sys.exit(1)

        except FileNotFoundError as e:
            logger.error(str(e))
            sys.exit(1)
    else:
        success, results = validator.validate_directory()
        validator.print_summary(results)

        if args.strict and any(any(errors.values()) for errors in results.values()):
            logger.error("Validation failed in strict mode: issues found")
            sys.exit(1)

    logger.info("Validation complete")
    sys.exit(0)


if __name__ == '__main__':
    main()
