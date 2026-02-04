# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-05

Initial stable release for OSS.

### Added
- **API Documentation**: OpenAPI 3.0 specification with interactive Swagger UI.
- **Reliability Features**: Idempotency key support for order creation.
- **Concurrency Control**: Optimistic locking for menu updates.
- **Security**: Rate limiting integrated using `rack-attack`.
- **Standardized Error Handling**: Unified JSON error response format across all endpoints.
- **Analytics**: Daily sales aggregation and reporting API.
- **Documentation**: Professional OSS toolkit including LICENSE (MIT), CONTRIBUTING.md, and SECURITY.md.
- **Developer Experience**: Docker/Docker Compose setup and example quick-start scripts.
- **Testing**: Comprehensive 144 RSpec test suite with GitHub Actions CI.

### Key Components
- `ErrorCode`: Centralized error code management.
- `ErrorHandler`: Consistent error response rendering.
- `DailyStatsAggregator`: SQL-optimized bulk aggregation of sales data.
- `OrderCreator`: Robust order placement service with transaction integrity.

---

**Made with ❤️ for the restaurant industry**
