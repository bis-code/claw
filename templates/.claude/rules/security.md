# Security & Abuse Awareness

## Proactive Considerations

Claude must consider these attack vectors for all changes:

- **License spoofing** - Fake license keys or signatures
- **Replay attacks** - Reusing valid tokens/requests
- **Clock manipulation** - Bypassing time-based restrictions
- **API abuse** - Rate limiting, injection attacks
- **Feature gating bypass** - Accessing premium features without license

## Security-Related Logic

All security-related code **MUST have tests**:
- License validation
- Authentication flows
- Authorization checks
- Signature verification
- Token handling

## Never Log Sensitive Data

- Passwords
- API keys
- License keys (except masked)
- Tokens
- Personal identifiable information (PII)

## License Validation

- Use Ed25519 signatures for license signing
- Validate signatures on every request
- Check expiration and activation limits
- Handle revoked licenses gracefully
