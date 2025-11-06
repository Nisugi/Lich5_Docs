"""
Base LLM Provider Abstract Class
Provides common interface for all LLM providers
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
import time
import logging
from dataclasses import dataclass

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


@dataclass
class ProviderConfig:
    """Configuration for an LLM provider"""
    name: str
    model: str
    max_tokens: int = 4096
    temperature: float = 0.0
    api_key: Optional[str] = None

    # Rate limiting
    requests_per_minute: Optional[int] = None
    requests_per_day: Optional[int] = None

    # Cost tracking
    cost_per_1m_input: Optional[float] = None
    cost_per_1m_output: Optional[float] = None


class LLMProvider(ABC):
    """Abstract base class for LLM providers"""

    def __init__(self, config: ProviderConfig):
        self.config = config
        self.request_count = 0
        self.daily_request_count = 0
        self.last_request_time = 0
        self.estimated_cost = 0.0

    @abstractmethod
    def generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """
        Generate documentation using the LLM

        Args:
            prompt: The user prompt
            system_prompt: Optional system prompt for context

        Returns:
            Generated text response
        """
        pass

    def _enforce_rate_limit(self):
        """Enforce rate limits if configured"""
        if self.config.requests_per_minute:
            elapsed = time.time() - self.last_request_time
            if elapsed < 60 / self.config.requests_per_minute:
                sleep_time = (60 / self.config.requests_per_minute) - elapsed
                logger.info(f"Rate limiting: sleeping for {sleep_time:.2f}s")
                time.sleep(sleep_time)

        if self.config.requests_per_day and self.daily_request_count >= self.config.requests_per_day:
            raise Exception(f"Daily request limit ({self.config.requests_per_day}) reached")

        self.last_request_time = time.time()
        self.request_count += 1
        self.daily_request_count += 1

    def _estimate_tokens(self, text: str) -> int:
        """Rough estimation of token count"""
        # Approximate: 1 token ~= 4 characters
        return len(text) // 4

    def _track_cost(self, input_text: str, output_text: str):
        """Track estimated API costs"""
        if self.config.cost_per_1m_input and self.config.cost_per_1m_output:
            input_tokens = self._estimate_tokens(input_text)
            output_tokens = self._estimate_tokens(output_text)

            cost = (input_tokens * self.config.cost_per_1m_input / 1_000_000 +
                   output_tokens * self.config.cost_per_1m_output / 1_000_000)

            self.estimated_cost += cost
            logger.debug(f"Request cost: ${cost:.4f} (Total: ${self.estimated_cost:.4f})")

    def get_stats(self) -> Dict[str, Any]:
        """Get provider statistics"""
        return {
            "provider": self.config.name,
            "model": self.config.model,
            "requests": self.request_count,
            "daily_requests": self.daily_request_count,
            "estimated_cost": f"${self.estimated_cost:.4f}" if self.estimated_cost > 0 else "N/A"
        }

    def reset_daily_counter(self):
        """Reset daily request counter (call this daily)"""
        self.daily_request_count = 0
        logger.info(f"Reset daily counter for {self.config.name}")