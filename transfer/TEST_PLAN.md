# Pre-Transfer Test Plan

Complete these tests before transferring to Elanthia Online.

## Local Testing

### 1. Mock Provider Tests
- [ ] Run: `python test_provider.py --provider mock`
- [ ] Verify output created in `test_output/`
- [ ] Check mock documentation is generated

### 2. Gemini Provider Tests (requires API key)
- [ ] Set `GEMINI_API_KEY` environment variable
- [ ] Run: `python test_provider.py --provider gemini --file tests/samples/version.rb`
- [ ] Verify YARD documentation generated
- [ ] Check quality of documentation

### 3. Full Directory Test
- [ ] Run: `python generate_docs.py tests/samples --provider mock`
- [ ] Verify all .rb files processed
- [ ] Check output directory structure
- [ ] Verify metadata.json created

## GitHub Actions Testing (after push)

### 4. Manual Workflow Test
- [ ] Push to your GitHub repository
- [ ] Add GEMINI_API_KEY secret (or use mock)
- [ ] Run manual-docs.yml workflow with mock provider
- [ ] Verify PR is created
- [ ] Check documentation in PR

### 5. Update Checker Test
- [ ] Run check-updates.yml manually
- [ ] Verify it checks Lich repository
- [ ] Confirm issue creation works (if new release)

## Quality Verification

### 6. Documentation Quality
- [ ] Generated docs include:
  - [ ] Class/module descriptions
  - [ ] Method documentation
  - [ ] Parameter descriptions with types
  - [ ] Return value documentation
  - [ ] Usage examples
- [ ] YARD syntax is valid
- [ ] No missing methods

### 7. Error Handling
- [ ] Test with non-existent file
- [ ] Test with empty directory
- [ ] Test without API key (should fail gracefully)
- [ ] Test with invalid provider name

## Performance Checks

### 8. Rate Limiting
- [ ] Verify rate limit enforcement (mock provider)
- [ ] Check daily quota tracking
- [ ] Confirm warnings when approaching limits

### 9. Large File Handling
- [ ] Test with file > 300 lines
- [ ] Verify chunking works correctly
- [ ] Check reassembled documentation is complete

## Integration Tests

### 10. End-to-End Test
- [ ] Clone fresh copy
- [ ] Install dependencies: `pip install -r requirements.txt`
- [ ] Set up .env file
- [ ] Run documentation generation
- [ ] Verify output quality

## Sign-off

- [ ] All tests passed
- [ ] Documentation quality acceptable
- [ ] No sensitive data in code
- [ ] README is comprehensive
- [ ] Transfer guide is clear

**Tester:** ________________
**Date:** ________________
**Ready for transfer:** Yes / No

## Notes

_Add any issues found or recommendations:_

---

## Quick Test Commands

```bash
# Minimal test (no API needed)
python test_provider.py --provider mock

# Check environment
python -c "from src.providers import ProviderFactory; print(ProviderFactory.validate_environment('mock'))"

# Test with sample files
python generate_docs.py tests/samples --provider mock --yard

# View provider info
python -c "from src.providers import ProviderFactory; import json; print(json.dumps(ProviderFactory.get_provider_info(), indent=2))"
```