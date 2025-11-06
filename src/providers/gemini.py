"""
Google Gemini Provider Implementation
Optimized for free tier usage with Gemini 2.0 Flash
"""

import os
import logging
from typing import Optional
from .base import LLMProvider, ProviderConfig

logger = logging.getLogger(__name__)

# Lazy import to avoid dependency issues when not using Gemini
genai = None


class GeminiProvider(LLMProvider):
    """Google Gemini provider with free tier optimization"""

    def __init__(self, config: Optional[ProviderConfig] = None):
        # Default configuration for Gemini 2.0 Flash free tier
        # Note: Using gemini-2.0-flash-exp (experimental version)
        # Will update to stable "gemini-2.0-flash" when available
        if config is None:
            config = ProviderConfig(
                name="gemini",
                model="gemini-2.0-flash-exp",  # Current 2.0 Flash model
                max_tokens=8192,  # 2.0 Flash supports larger outputs
                temperature=0.0,
                # Free tier limits (same as 1.5)
                requests_per_minute=15,
                requests_per_day=1500,
                # No costs for free tier
                cost_per_1m_input=0,
                cost_per_1m_output=0
            )

        super().__init__(config)

        # Lazy import Gemini
        global genai
        if genai is None:
            try:
                import google.generativeai as genai
            except ImportError:
                raise ImportError(
                    "google-generativeai package not installed. "
                    "Install with: pip install google-generativeai"
                )

        # Initialize Gemini
        api_key = config.api_key or os.environ.get('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment or config")

        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(config.model)

        # Set safety settings to be less restrictive for code
        self.safety_settings = [
            {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_HATE_SPEECH",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_ONLY_HIGH"
            },
            {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_ONLY_HIGH"
            }
        ]

    def generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """
        Generate documentation using Gemini

        Args:
            prompt: The user prompt
            system_prompt: Optional system prompt (combined with user prompt for Gemini)

        Returns:
            Generated documentation text
        """
        # Check quotas before making request
        if self.daily_request_count >= self.config.requests_per_day:
            remaining_quota = self.config.requests_per_day - self.daily_request_count
            logger.warning(f"⚠️  Approaching daily limit! {remaining_quota} requests remaining")
            if remaining_quota <= 0:
                raise Exception(
                    f"Daily quota exhausted ({self.config.requests_per_day} requests). "
                    f"Wait until tomorrow or switch to another provider."
                )

        # Enforce rate limiting
        self._enforce_rate_limit()

        # Combine system and user prompts (Gemini doesn't have separate system prompts)
        if system_prompt:
            full_prompt = f"{system_prompt}\n\n{prompt}"
        else:
            full_prompt = prompt

        try:
            logger.info(f"Sending request to Gemini ({self.daily_request_count}/{self.config.requests_per_day} daily)")

            # Generate response
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=self.config.max_tokens,
                    temperature=self.config.temperature,
                ),
                safety_settings=self.safety_settings
            )

            # Extract text
            result_text = response.text

            # Track usage (no cost for free tier)
            self._track_cost(full_prompt, result_text)

            # Log remaining quota
            remaining = self.config.requests_per_day - self.daily_request_count
            if remaining < 100:
                logger.warning(f"⚠️  Low quota warning: {remaining} requests remaining today")

            return result_text

        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            if "quota" in str(e).lower():
                raise Exception(
                    f"Gemini quota exceeded. Daily limit: {self.config.requests_per_day}. "
                    f"Consider waiting or switching to OpenAI if you have credits."
                )
            raise

    def estimate_job_feasibility(self, num_files: int, avg_chunks_per_file: int = 1) -> dict:
        """
        Estimate if a documentation job will fit within quotas

        Args:
            num_files: Number of files to process
            avg_chunks_per_file: Average chunks per file (for large files)

        Returns:
            Dictionary with feasibility analysis
        """
        total_requests = num_files * avg_chunks_per_file
        requests_remaining = self.config.requests_per_day - self.daily_request_count

        can_complete = total_requests <= requests_remaining
        time_estimate = total_requests * (60 / self.config.requests_per_minute) / 60  # in minutes

        return {
            "total_requests_needed": total_requests,
            "requests_remaining_today": requests_remaining,
            "can_complete_today": can_complete,
            "estimated_time_minutes": round(time_estimate, 1),
            "recommendation": (
                "✅ Job can be completed within free tier limits" if can_complete
                else f"❌ Job requires {total_requests} requests but only {requests_remaining} remaining today. "
                     f"Consider splitting the job or waiting until tomorrow."
            )
        }