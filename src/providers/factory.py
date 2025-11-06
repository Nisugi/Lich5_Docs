"""
Provider Factory
Handles provider selection based on configuration
"""

import os
import logging
from typing import Optional, Dict, Any
from .base import LLMProvider, ProviderConfig
from .mock import MockProvider

logger = logging.getLogger(__name__)


class ProviderFactory:
    """Factory for creating LLM providers based on configuration"""

    @staticmethod
    def create_provider(
        provider_name: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None
    ) -> LLMProvider:
        """
        Create an LLM provider instance

        Args:
            provider_name: Name of provider ('gemini', 'openai', 'mock', 'anthropic')
                          If None, uses LLM_PROVIDER env var or defaults to 'openai'
            config: Optional configuration dict to override defaults

        Returns:
            LLMProvider instance

        Raises:
            ValueError: If provider name is not recognized
        """
        # Determine provider
        if provider_name is None:
            provider_name = os.environ.get('LLM_PROVIDER', 'openai').lower()

        logger.info(f"Initializing {provider_name} provider")

        # Create provider-specific config if provided
        provider_config = None
        if config:
            provider_config = ProviderConfig(**config)

        # Create provider instance (with lazy imports)
        if provider_name == 'gemini':
            try:
                from .gemini import GeminiProvider
                provider = GeminiProvider(provider_config)
                logger.info("[OK] Using Gemini provider (FREE tier)")
            except ImportError as e:
                raise ImportError(
                    "Cannot use Gemini provider: google-generativeai not installed. "
                    "Install with: pip install google-generativeai"
                )

        elif provider_name == 'openai':
            try:
                from .openai_provider import OpenAIProvider
                provider = OpenAIProvider(provider_config)
                logger.warning("[PAID] Using OpenAI provider (costs will be incurred)")
            except ImportError as e:
                raise ImportError(
                    "Cannot use OpenAI provider: openai not installed. "
                    "Install with: pip install openai"
                )

        elif provider_name == 'anthropic':
            try:
                from .anthropic_provider import AnthropicProvider
                provider = AnthropicProvider(provider_config)
                logger.info("[PAID] Using Anthropic provider (Claude - high quality)")
            except ImportError as e:
                raise ImportError(
                    "Cannot use Anthropic provider: anthropic not installed. "
                    "Install with: pip install anthropic"
                )

        elif provider_name == 'mock':
            provider = MockProvider(provider_config)
            logger.info("[MOCK] Using Mock provider (testing mode - no API calls)")

        else:
            raise ValueError(
                f"Unknown provider: {provider_name}. "
                f"Supported providers: openai, anthropic, gemini, mock"
            )

        # Log provider stats
        stats = provider.get_stats()
        logger.info(f"Provider initialized: {stats}")

        return provider

    @staticmethod
    def get_provider_info() -> Dict[str, Any]:
        """
        Get information about available providers

        Returns:
            Dictionary with provider information
        """
        return {
            "available_providers": {
                "openai": {
                    "description": "OpenAI GPT-4o-mini",
                    "cost": "~$0.50-2.00 per full documentation run",
                    "limits": "60 requests/min (pay per use)",
                    "model": "gpt-4o-mini",
                    "recommended": True,
                    "note": "Best balance of quality, speed, and cost"
                },
                "anthropic": {
                    "description": "Anthropic Claude 3 Haiku",
                    "cost": "~$0.25-1.00 per full documentation run",
                    "limits": "50 requests/min (pay per use)",
                    "model": "claude-3-haiku-20240307",
                    "recommended": True,
                    "note": "High quality documentation, good YARD compliance"
                },
                "gemini": {
                    "description": "Google Gemini 2.0 Flash",
                    "cost": "FREE (but extremely limited)",
                    "limits": "~10 requests/min, ~200 requests/day",
                    "model": "gemini-2.0-flash-exp",
                    "recommended": False,
                    "note": "Only for small projects due to severe rate limits"
                },
                "mock": {
                    "description": "Mock provider for testing",
                    "cost": "FREE",
                    "limits": "None",
                    "model": "mock-model",
                    "recommended": False,
                    "note": "For testing pipeline without API calls"
                }
            },
            "current_provider": os.environ.get('LLM_PROVIDER', 'openai'),
            "env_var": "LLM_PROVIDER"
        }

    @staticmethod
    def validate_environment(provider_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Validate that required environment variables are set for the provider

        Args:
            provider_name: Provider to validate (defaults to LLM_PROVIDER env var)

        Returns:
            Validation results
        """
        if provider_name is None:
            provider_name = os.environ.get('LLM_PROVIDER', 'openai').lower()

        results = {
            "provider": provider_name,
            "valid": False,
            "missing": [],
            "warnings": []
        }

        if provider_name == 'gemini':
            if not os.environ.get('GEMINI_API_KEY'):
                results["missing"].append("GEMINI_API_KEY")
            else:
                results["valid"] = True

        elif provider_name == 'openai':
            if not os.environ.get('OPENAI_API_KEY'):
                results["missing"].append("OPENAI_API_KEY")
            else:
                results["valid"] = True
                results["warnings"].append("OpenAI will incur costs (~$0.50-2.00 per run)")

        elif provider_name == 'anthropic':
            if not os.environ.get('ANTHROPIC_API_KEY'):
                results["missing"].append("ANTHROPIC_API_KEY")
            else:
                results["valid"] = True
                results["warnings"].append("Anthropic will incur costs (~$0.25-1.00 per run)")

        elif provider_name == 'mock':
            results["valid"] = True
            results["warnings"].append("Mock mode - no actual documentation will be generated")

        else:
            results["warnings"].append(f"Unknown provider: {provider_name}")

        return results


# Convenience function for quick provider creation
def get_provider(provider_name: Optional[str] = None) -> LLMProvider:
    """
    Quick helper to get a provider instance

    Args:
        provider_name: Optional provider name (defaults to env var or 'gemini')

    Returns:
        LLMProvider instance
    """
    return ProviderFactory.create_provider(provider_name)