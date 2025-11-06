"""
OpenAI Provider Implementation
Backup option when Gemini quality isn't sufficient
"""

import os
import logging
from typing import Optional
from .base import LLMProvider, ProviderConfig

logger = logging.getLogger(__name__)

# Lazy import to avoid dependency issues when not using OpenAI
OpenAI = None


class OpenAIProvider(LLMProvider):
    """OpenAI provider for cases where higher quality is needed"""

    def __init__(self, config: Optional[ProviderConfig] = None):
        # Default configuration for GPT-4o-mini (cheapest good model)
        if config is None:
            config = ProviderConfig(
                name="openai",
                model="gpt-4o-mini",
                max_tokens=4096,
                temperature=0.0,
                # No hard limits, but track costs
                requests_per_minute=60,  # Reasonable limit
                requests_per_day=None,   # No daily limit
                # GPT-4o-mini pricing (as of 2024)
                cost_per_1m_input=0.15,   # $0.15 per 1M input tokens
                cost_per_1m_output=0.60   # $0.60 per 1M output tokens
            )

        super().__init__(config)

        # Lazy import OpenAI
        global OpenAI
        if OpenAI is None:
            try:
                from openai import OpenAI
            except ImportError:
                raise ImportError(
                    "openai package not installed. "
                    "Install with: pip install openai"
                )

        # Initialize OpenAI client
        api_key = config.api_key or os.environ.get('OPENAI_API_KEY')
        if not api_key:
            raise ValueError(
                "OPENAI_API_KEY not found in environment or config. "
                "OpenAI is a backup option - only configure if Gemini quality is insufficient."
            )

        self.client = OpenAI(api_key=api_key)

    def generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """
        Generate documentation using OpenAI

        Args:
            prompt: The user prompt
            system_prompt: Optional system prompt for context

        Returns:
            Generated documentation text
        """
        # Warn about costs
        if self.request_count == 0:
            logger.warning("⚠️  Using OpenAI (paid API). Costs will be incurred!")
            logger.info(f"Estimated costs: ${self.config.cost_per_1m_input}/1M input, "
                       f"${self.config.cost_per_1m_output}/1M output tokens")

        # Enforce rate limiting
        self._enforce_rate_limit()

        try:
            # Build messages
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})

            logger.info(f"Sending request to OpenAI ({self.config.model})")

            # Make API call
            response = self.client.chat.completions.create(
                model=self.config.model,
                messages=messages,
                max_tokens=self.config.max_tokens,
                temperature=self.config.temperature,
            )

            # Extract response
            result_text = response.choices[0].message.content

            # Track costs
            self._track_cost(prompt + (system_prompt or ""), result_text)

            # Log estimated cost
            if self.estimated_cost > 0:
                logger.info(f"💰 Estimated cost so far: ${self.estimated_cost:.4f}")

            return result_text

        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            if "insufficient_quota" in str(e):
                raise Exception(
                    "OpenAI API quota exceeded. Please check your OpenAI account balance."
                )
            raise

    def estimate_job_cost(self, num_files: int, avg_lines_per_file: int = 500) -> dict:
        """
        Estimate the cost of processing files with OpenAI

        Args:
            num_files: Number of files to process
            avg_lines_per_file: Average lines per file

        Returns:
            Cost estimation
        """
        # Rough estimates
        avg_chars_per_file = avg_lines_per_file * 80  # ~80 chars per line
        avg_tokens_per_file = avg_chars_per_file // 4  # ~4 chars per token

        # Assume output is roughly same size as input for docs
        total_input_tokens = num_files * avg_tokens_per_file
        total_output_tokens = num_files * avg_tokens_per_file

        estimated_cost = (
            total_input_tokens * self.config.cost_per_1m_input / 1_000_000 +
            total_output_tokens * self.config.cost_per_1m_output / 1_000_000
        )

        return {
            "num_files": num_files,
            "estimated_input_tokens": total_input_tokens,
            "estimated_output_tokens": total_output_tokens,
            "estimated_cost": f"${estimated_cost:.2f}",
            "cost_per_file": f"${estimated_cost / num_files:.4f}",
            "model": self.config.model,
            "warning": "⚠️  This is a rough estimate. Actual costs may vary."
        }