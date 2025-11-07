#!/usr/bin/env python3
"""
Lich5 Documentation Generator
Main script for generating YARD-compatible documentation for Lich5 Ruby code
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import argparse
import json
import logging
import re
import time
import hashlib
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional

from providers import get_provider, ProviderFactory

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class Lich5DocumentationGenerator:
    """Main documentation generator for Lich5 Ruby code"""

    def __init__(self, provider_name: Optional[str] = None, output_dir: Optional[str] = None,
                 incremental: bool = True, force_rebuild: bool = False, parallel_workers: int = None):
        """
        Initialize the documentation generator

        Args:
            provider_name: LLM provider to use (defaults to env var or 'openai')
            output_dir: Output directory for documentation (defaults to 'output/latest')
            incremental: Enable incremental processing (skip already documented files)
            force_rebuild: Force reprocessing of all files even if already documented
            parallel_workers: Number of parallel workers (None = auto-detect based on provider)
        """
        self.provider_name = provider_name or os.environ.get('LLM_PROVIDER', 'openai')
        self.incremental = incremental and not force_rebuild
        self.force_rebuild = force_rebuild

        # Thread safety - use RLock (reentrant) to allow nested acquisitions
        self.manifest_lock = threading.RLock()
        self.file_lock = threading.RLock()

        # Auto-detect parallel workers based on provider rate limits
        if parallel_workers is None:
            if self.provider_name == 'openai':
                self.parallel_workers = 8  # With 400 RPM, we can handle 8 parallel workers easily
            elif self.provider_name == 'anthropic':
                self.parallel_workers = 4  # More conservative with 50 RPM
            else:
                self.parallel_workers = 1  # Sequential for other providers
        else:
            self.parallel_workers = parallel_workers

        # Set up output directory
        if output_dir:
            self.output_dir = Path(output_dir)
        else:
            # Use 'latest' directory for incremental processing
            self.output_dir = Path('output') / 'latest'

        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Initialize provider
        logger.info(f"Initializing {self.provider_name} provider")
        self.provider = get_provider(self.provider_name)

        # Track documentation
        self.documentation = {}
        self.failed_files = []

        # Load existing manifest for incremental processing
        self.manifest_file = self.output_dir / 'manifest.json'
        self.manifest = self.load_manifest()

        logger.info(f"Documentation generator initialized")
        logger.info(f"Provider: {self.provider_name}")
        logger.info(f"Output directory: {self.output_dir}")
        logger.info(f"Incremental mode: {self.incremental}")
        if self.incremental and self.manifest.get('processed_files'):
            logger.info(f"Found {len(self.manifest['processed_files'])} already processed files")

    def load_manifest(self) -> dict:
        """Load the manifest file tracking processed files"""
        if self.manifest_file.exists():
            try:
                with open(self.manifest_file, 'r') as f:
                    manifest = json.load(f)
                logger.info(f"Loaded manifest with {len(manifest.get('processed_files', []))} processed files")
                return manifest
            except Exception as e:
                logger.warning(f"Failed to load manifest: {e}")
                return {'processed_files': {}, 'failed_files': [], 'timestamp': datetime.now().isoformat()}
        return {'processed_files': {}, 'failed_files': [], 'timestamp': datetime.now().isoformat()}

    def save_manifest(self):
        """Save the manifest file (thread-safe)"""
        with self.manifest_lock:
            try:
                with open(self.manifest_file, 'w') as f:
                    json.dump(self.manifest, f, indent=2, default=str)
            except Exception as e:
                logger.error(f"Failed to save manifest: {e}")

    def compute_code_hash(self, content: str) -> str:
        """
        Compute hash of Ruby code excluding YARD comments
        This allows us to detect actual code changes vs documentation changes
        """
        lines = content.split('\n')
        code_lines = []
        in_yard_comment = False

        for line in lines:
            stripped = line.strip()

            # Skip YARD comment blocks
            if stripped.startswith('#') and any(tag in stripped for tag in ['@param', '@return', '@example', '@note', '@see', '@yield']):
                continue
            # Skip regular comment lines that look like documentation
            elif stripped.startswith('#') and len(stripped) > 1 and stripped[1] == ' ':
                # But keep shebang and encoding comments
                if stripped.startswith('#!') or 'coding:' in stripped or 'encoding:' in stripped:
                    code_lines.append(line)
            else:
                # Include actual code lines
                code_lines.append(line)

        # Compute hash of the actual code
        code_content = '\n'.join(code_lines)
        return hashlib.sha256(code_content.encode('utf-8')).hexdigest()[:16]

    def is_file_processed(self, file_path: Path) -> bool:
        """Check if a file has already been processed and hasn't changed"""
        if not self.incremental:
            return False

        relative_path = str(file_path)
        if relative_path in self.manifest.get('processed_files', {}):
            # Check if output file actually exists
            output_file = self.output_dir / 'documented' / file_path.name
            if not output_file.exists():
                logger.info(f"  Output file missing, reprocessing: {file_path.name}")
                return False

            # Check if source file has changed by comparing hashes
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    current_content = f.read()
                current_hash = self.compute_code_hash(current_content)

                stored_info = self.manifest['processed_files'][relative_path]
                stored_hash = stored_info.get('content_hash')

                if current_hash != stored_hash:
                    logger.info(f"  Source file changed, reprocessing: {file_path.name}")
                    logger.debug(f"    Hash changed: {stored_hash} -> {current_hash}")
                    return False
                else:
                    logger.info(f"  Skipping (unchanged): {file_path.name}")
                    return True

            except Exception as e:
                logger.warning(f"  Error checking file hash, reprocessing: {e}")
                return False

        return False

    def mark_file_processed(self, file_path: Path, success: bool = True, content: str = None):
        """Mark a file as processed in the manifest with content hash (thread-safe)"""
        with self.manifest_lock:
            relative_path = str(file_path)
            if success:
                if 'processed_files' not in self.manifest:
                    self.manifest['processed_files'] = {}

                # Compute hash of the source file (without comments)
                content_hash = None
                if content:
                    content_hash = self.compute_code_hash(content)
                else:
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content_hash = self.compute_code_hash(f.read())
                    except Exception as e:
                        logger.warning(f"Could not compute hash for {file_path}: {e}")

                self.manifest['processed_files'][relative_path] = {
                    'timestamp': datetime.now().isoformat(),
                    'provider': self.provider_name,
                    'content_hash': content_hash,
                    'file_name': file_path.name
                }
            else:
                if 'failed_files' not in self.manifest:
                    self.manifest['failed_files'] = []
                if relative_path not in self.manifest['failed_files']:
                    self.manifest['failed_files'].append(relative_path)

            # Save manifest after each file (in case of interruption)
            self.save_manifest()

    def create_documentation_prompt(self, file_name: str, content: str) -> tuple[str, str]:
        """
        Create prompts for documentation generation

        Returns:
            (system_prompt, user_prompt) tuple
        """
        system_prompt = """You are an expert Ruby documentation specialist.
Your task is to generate YARD-compatible documentation for Ruby code.
You will return JSON with documentation comments and their anchor points."""

        user_prompt = f"""Analyze this Ruby file from the Lich5 project: **{file_name}**

```ruby
{content}
```

Generate **YARD-compatible** documentation for every public class, module, method, and constant.

Documentation rules:
1. For classes/modules:
   - Brief description on first line
   - Longer description if needed
   - @example tag with usage

2. For methods:
   - Brief description
   - @param tags for ALL parameters with [Type] and description
   - @return tag with [Type] and what it returns
   - @raise tags for exceptions
   - @example tag with actual usage
   - @note for important caveats

3. For constants:
   - Brief description comment above

Return a JSON array where each entry contains:
- "anchor": The exact line to insert before (e.g., "class Foo", "def bar(x, y)", "MODULE_NAME = ")
- "indent": The indentation level (number of spaces before the anchor line)
- "comment": The YARD comment block as a single string with \\n for newlines

Example output format:
```json
[
  {{
    "anchor": "class GameObj",
    "indent": 0,
    "comment": "# Represents a game object\\n# @example Creating a game object\\n#   obj = GameObj.new"
  }},
  {{
    "anchor": "def initialize(id, noun)",
    "indent": 2,
    "comment": "# Initializes a new game object\\n# @param id [String] The object ID\\n# @param noun [String] The object noun\\n# @return [GameObj]"
  }}
]
```

IMPORTANT: Return ONLY the JSON array, no other text."""

        return system_prompt, user_prompt

    def process_file(self, file_path: Path) -> Optional[str]:
        """
        Process a single Ruby file and generate documentation using JSON-based approach

        Args:
            file_path: Path to Ruby file

        Returns:
            Generated documentation or None if failed
        """
        logger.info(f"Processing: {file_path.name}")

        try:
            # Read original file
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()

            # Get file stats
            lines = len(original_content.split('\n'))
            logger.info(f"  Lines: {lines}, Characters: {len(original_content)}")

            # Create prompts for JSON-based documentation
            system_prompt, user_prompt = self.create_documentation_prompt(
                file_path.name,
                original_content
            )

            # Generate JSON with comments and anchors
            logger.info(f"  Requesting documentation from {self.provider_name}...")
            result = self.provider.generate(user_prompt, system_prompt)

            # Parse JSON response
            comments = self.extract_comments_json(result)

            if not comments:
                logger.error(f"  No comments extracted from response")
                self.failed_files.append(file_path.name)
                return None

            logger.info(f"  Extracted {len(comments)} documentation entries")

            # Insert comments into original code
            documented_code = self.insert_comments(original_content, comments)

            # Store documentation
            self.documentation[file_path.name] = {
                'original': original_content,
                'documented': documented_code,
                'timestamp': datetime.now().isoformat()
            }

            logger.info(f"  ✅ Successfully documented {file_path.name}")
            return documented_code

        except Exception as e:
            logger.error(f"  ❌ Failed to process {file_path.name}: {e}")
            import traceback
            logger.debug(traceback.format_exc())
            self.failed_files.append(file_path.name)
            return None

    def extract_comments_json(self, response: str) -> List[Dict[str, Any]]:
        """
        Extract JSON array of comments from LLM response

        Returns:
            List of comment entries with anchor, indent, and comment fields
        """
        # Try to find JSON code blocks first
        json_blocks = re.findall(r'```json\s*(.*?)```', response, re.DOTALL)

        if json_blocks:
            json_text = json_blocks[0].strip()
        else:
            # Try to find JSON array directly
            json_match = re.search(r'\[\s*\{.*?\}\s*\]', response, re.DOTALL)
            if json_match:
                json_text = json_match.group(0)
            else:
                # Last resort: assume entire response is JSON
                json_text = response.strip()

        try:
            comments = json.loads(json_text)
            if not isinstance(comments, list):
                raise ValueError("Expected JSON array")

            logger.debug(f"Extracted {len(comments)} comment entries from response")
            return comments

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON response: {e}")
            logger.debug(f"Response text: {response[:500]}")
            return []

    def insert_comments(self, original_content: str, comments: List[Dict[str, Any]]) -> str:
        """
        Insert YARD comments into original Ruby code using anchors

        Args:
            original_content: Original Ruby source code
            comments: List of comment entries with anchor, indent, and comment fields

        Returns:
            Ruby code with comments inserted
        """
        if not comments:
            logger.warning("No comments to insert")
            return original_content

        lines = original_content.split('\n')

        # Track which lines we've already added comments to
        inserted_at_lines = set()

        # Process each comment entry
        for entry in comments:
            try:
                anchor = entry.get('anchor', '').strip()
                indent = entry.get('indent', 0)
                comment_text = entry.get('comment', '').strip()

                if not anchor or not comment_text:
                    logger.warning(f"Skipping invalid entry: missing anchor or comment")
                    continue

                # Find the anchor line
                anchor_line_idx = None
                for i, line in enumerate(lines):
                    # Check if this line contains the anchor
                    # Strip leading/trailing whitespace for comparison
                    if anchor in line and i not in inserted_at_lines:
                        anchor_line_idx = i
                        break

                if anchor_line_idx is None:
                    logger.warning(f"Could not find anchor: {anchor[:50]}")
                    continue

                # Insert comment lines before the anchor
                indent_str = ' ' * indent
                comment_lines = []

                for comment_line in comment_text.split('\n'):
                    # Add proper indentation to each comment line
                    if comment_line.strip():
                        comment_lines.append(f"{indent_str}{comment_line}")
                    else:
                        comment_lines.append('')

                # Insert the comment block before the anchor line
                for offset, comment_line in enumerate(comment_lines):
                    lines.insert(anchor_line_idx + offset, comment_line)

                # Mark this line (and the new lines) as having comments
                inserted_at_lines.add(anchor_line_idx)

                logger.debug(f"Inserted comment at line {anchor_line_idx} for anchor: {anchor[:30]}")

            except Exception as e:
                logger.error(f"Error inserting comment: {e}")
                continue

        return '\n'.join(lines)

    def _process_single_file(self, file_path: Path, index: int, total: int) -> bool:
        """Process a single file (used for parallel processing)"""
        try:
            logger.info(f"[{index}/{total}] Processing: {file_path.name}")

            result = self.process_file(file_path)
            if result:
                # Save documented file
                output_file = self.output_dir / 'documented' / file_path.name
                output_file.parent.mkdir(exist_ok=True, parents=True)

                with self.file_lock:
                    with open(output_file, 'w', encoding='utf-8') as f:
                        f.write(result)

                # Mark file as successfully processed
                self.mark_file_processed(file_path, success=True)
                return True
            else:
                # Mark file as failed
                self.mark_file_processed(file_path, success=False)
                return False
        except Exception as e:
            logger.error(f"Error processing {file_path.name}: {e}")
            self.mark_file_processed(file_path, success=False)
            return False

    def _process_files_parallel(self, files: List[Path]) -> int:
        """Process multiple files in parallel"""
        processed_count = 0
        total_files = len(files)

        logger.info(f"Starting parallel processing with {self.parallel_workers} workers...")

        with ThreadPoolExecutor(max_workers=self.parallel_workers) as executor:
            # Submit all tasks
            future_to_file = {
                executor.submit(self._process_single_file, file, i, total_files): file
                for i, file in enumerate(files, 1)
            }

            # Process completed futures
            for future in as_completed(future_to_file):
                file_path = future_to_file[future]
                try:
                    if future.result():
                        processed_count += 1
                        logger.info(f"✓ Completed: {file_path.name}")
                    else:
                        logger.warning(f"✗ Failed: {file_path.name}")
                except Exception as e:
                    logger.error(f"Exception processing {file_path.name}: {e}")

        return processed_count

    def process_directory(self, directory: Path, pattern: str = "*.rb") -> Dict[str, Any]:
        """
        Process all Ruby files in a directory

        Args:
            directory: Directory containing Ruby files
            pattern: File pattern to match (default: *.rb)

        Returns:
            Processing statistics
        """
        logger.info(f"Processing directory: {directory}")

        # Find all Ruby files recursively
        all_ruby_files = list(directory.rglob(pattern))

        # Exclude critranks directory (large data tables that don't need documentation)
        ruby_files = [f for f in all_ruby_files if 'critranks' not in str(f)]

        excluded_count = len(all_ruby_files) - len(ruby_files)
        if excluded_count > 0:
            logger.info(f"Excluded {excluded_count} files from critranks directory")

        logger.info(f"Found {len(ruby_files)} Ruby files to process")

        if not ruby_files:
            logger.warning("No Ruby files found!")
            return {'processed': 0, 'failed': 0}

        # Check feasibility for Gemini
        if self.provider_name == 'gemini' and hasattr(self.provider, 'estimate_job_feasibility'):
            feasibility = self.provider.estimate_job_feasibility(len(ruby_files), avg_chunks_per_file=2)
            logger.info(f"Feasibility check: {feasibility['recommendation']}")

            if not feasibility['can_complete_today']:
                logger.warning("Job may exceed daily quota. Consider processing in batches.")
                response = input("Continue anyway? (y/n): ")
                if response.lower() != 'y':
                    return {'processed': 0, 'failed': 0}

        # Process files (parallel or sequential based on settings)
        start_time = time.time()
        processed = 0

        # Filter out already processed files
        files_to_process = []
        for file_path in ruby_files:
            if self.is_file_processed(file_path):
                processed += 1  # Count as processed
                logger.info(f"Skipping (already processed): {file_path.name}")
            else:
                files_to_process.append(file_path)

        logger.info(f"\nFiles to process: {len(files_to_process)}")
        logger.info(f"Already processed: {processed}")
        logger.info(f"Parallel workers: {self.parallel_workers}")

        if files_to_process:
            if self.parallel_workers > 1 and len(files_to_process) > 1:
                # Parallel processing
                processed += self._process_files_parallel(files_to_process)
            else:
                # Sequential processing
                for i, file_path in enumerate(files_to_process, 1):
                    logger.info(f"\n[{i}/{len(files_to_process)}] Processing: {file_path.name}")

                    result = self.process_file(file_path)
                    if result:
                        processed += 1

                        # Save documented file
                        output_file = self.output_dir / 'documented' / file_path.name
                        output_file.parent.mkdir(exist_ok=True)

                        with open(output_file, 'w', encoding='utf-8') as f:
                            f.write(result)

                        # Mark file as successfully processed
                        self.mark_file_processed(file_path, success=True)
                    else:
                        # Mark file as failed
                        self.mark_file_processed(file_path, success=False)

        # Calculate statistics
        elapsed_time = time.time() - start_time
        stats = {
            'processed': processed,
            'failed': len(self.failed_files),
            'total': len(ruby_files),
            'elapsed_time': round(elapsed_time, 2),
            'provider': self.provider_name,
            'failed_files': self.failed_files
        }

        # Save metadata
        metadata_file = self.output_dir / 'metadata.json'
        with open(metadata_file, 'w') as f:
            json.dump({
                'stats': stats,
                'documentation': {k: {'timestamp': v['timestamp']} for k, v in self.documentation.items()},
                'provider_stats': self.provider.get_stats()
            }, f, indent=2)

        return stats

    def generate_yard_docs(self):
        """Generate YARD documentation files from the documented code"""
        logger.info("Generating YARD documentation...")

        yard_dir = self.output_dir / 'yard'
        yard_dir.mkdir(exist_ok=True)

        for file_name, doc_data in self.documentation.items():
            documented_code = doc_data['documented']

            # Extract only YARD comments
            yard_comments = []
            for line in documented_code.split('\n'):
                if line.strip().startswith('#'):
                    yard_comments.append(line)

            if yard_comments:
                output_file = yard_dir / f"{file_name}.yard"
                with open(output_file, 'w') as f:
                    f.write('\n'.join(yard_comments))

                logger.info(f"  Generated YARD: {output_file.name}")

        logger.info(f"YARD documentation saved to: {yard_dir}")

    def print_summary(self, stats: Dict[str, Any]):
        """Print a summary of the documentation generation"""
        print("\n" + "="*60)
        print("DOCUMENTATION GENERATION COMPLETE")
        print("="*60)
        print(f"Provider: {stats['provider']}")
        print(f"Processed: {stats['processed']}/{stats['total']} files")
        print(f"Failed: {stats['failed']} files")
        print(f"Time: {stats['elapsed_time']} seconds")
        print(f"Output: {self.output_dir}")

        if stats['failed_files']:
            print(f"\nFailed files:")
            for file in stats['failed_files']:
                print(f"  - {file}")

        # Show provider stats
        provider_stats = self.provider.get_stats()
        print(f"\nProvider statistics:")
        print(f"  Requests: {provider_stats['requests']}")
        if 'daily_requests' in provider_stats:
            print(f"  Daily requests: {provider_stats['daily_requests']}")
        if 'estimated_cost' in provider_stats:
            print(f"  Estimated cost: {provider_stats['estimated_cost']}")

        print("="*60)


def main():
    parser = argparse.ArgumentParser(description='Generate YARD documentation for Lich5')
    parser.add_argument(
        'input',
        help='Input directory containing Ruby files or single Ruby file'
    )
    parser.add_argument(
        '--provider',
        choices=['gemini', 'openai', 'mock', 'anthropic'],
        help='LLM provider to use (defaults to env var or openai)'
    )
    parser.add_argument(
        '--output',
        help='Output directory (defaults to output/{timestamp})'
    )
    parser.add_argument(
        '--pattern',
        default='*.rb',
        help='File pattern to match (default: *.rb)'
    )
    parser.add_argument(
        '--yard',
        action='store_true',
        help='Also generate YARD comment files'
    )
    parser.add_argument(
        '--force-rebuild',
        action='store_true',
        help='Force reprocessing of all files (disable incremental mode)'
    )
    parser.add_argument(
        '--no-incremental',
        action='store_true',
        help='Disable incremental processing (same as --force-rebuild)'
    )

    args = parser.parse_args()

    # Validate environment
    provider = args.provider or os.environ.get('LLM_PROVIDER', 'openai')
    validation = ProviderFactory.validate_environment(provider)

    if not validation['valid']:
        logger.error(f"Environment validation failed!")
        if validation['missing']:
            logger.error(f"Missing environment variables: {', '.join(validation['missing'])}")
            logger.info(f"Please set the required environment variables or check .env.example")
        sys.exit(1)

    # Show warnings
    for warning in validation.get('warnings', []):
        logger.warning(warning)

    # Create generator
    force_rebuild = args.force_rebuild or args.no_incremental
    generator = Lich5DocumentationGenerator(
        provider_name=args.provider,
        output_dir=args.output,
        force_rebuild=force_rebuild
    )

    # Process input
    input_path = Path(args.input)

    if input_path.is_file():
        # Single file mode
        result = generator.process_file(input_path)
        if result:
            output_file = generator.output_dir / input_path.name
            with open(output_file, 'w') as f:
                f.write(result)
            print(f"Documentation saved to: {output_file}")
        else:
            print("Failed to generate documentation")
            sys.exit(1)

    elif input_path.is_dir():
        # Directory mode
        stats = generator.process_directory(input_path, args.pattern)

        # Generate YARD if requested
        if args.yard:
            generator.generate_yard_docs()

        # Print summary
        generator.print_summary(stats)

        # Exit with error if any files failed
        if stats['failed'] > 0:
            sys.exit(1)

    else:
        logger.error(f"Input path does not exist: {input_path}")
        sys.exit(1)


if __name__ == '__main__':
    main()