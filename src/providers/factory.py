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
            provider_name: Name of provider ('gemini', 'openai', 'mock')
                          If None, uses LLM_PROVIDER env var or defaults to 'gemini'
            config: Optional configuration dict to override defaults

        Returns:
            LLMProvider instance

        Raises:
            ValueError: If provider name is not recognized
        """
        # Determine provider
        if provider_name is None:
            provider_name = os.environ.get('LLM_PROVIDER', 'gemini').lower()

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

        elif provider_name == 'mock':
            provider = MockProvider(provider_config)
            logger.info("[MOCK] Using Mock provider (testing mode - no API calls)")

        else:
            raise ValueError(
                f"Unknown provider: {provider_name}. "
                f"Supported providers: gemini, openai, mock"
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
                "gemini": {
                    "description": "Google Gemini 2.0 Flash",
                    "cost": "FREE",
                    "limits": "15 requests/min, 1500 requests/day",
                    "model": "gemini-2.0-flash-exp",
                    "recommended": True
                },
                "openai": {
                    "description": "OpenAI GPT-4o-mini",
                    "cost": "~$0.50-2.00 per full documentation run",
                    "limits": "No hard limits (pay per use)",
                    "model": "gpt-4o-mini",
                    "recommended": False,
                    "note": "Use only if Gemini quality is insufficient"
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
            "current_provider": os.environ.get('LLM_PROVIDER', 'gemini'),
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
            provider_name = os.environ.get('LLM_PROVIDER', 'gemini').lower()

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