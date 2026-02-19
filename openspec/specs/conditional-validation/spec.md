# conditional-validation Specification

## Purpose
TBD - created by archiving change add-equal-field-macro-and-when-property. Update Purpose after archive.
## Requirements
### Requirement: Conditional Validation

The `when` property MUST be supported by all validation macros. It SHALL allow specifying a boolean expression that determines when the validation should be executed.

#### Scenario: Basic conditional validation
- **Given**: 一个类有一个字段 `status` 和一个字段 `activeReason`
- **When**: `status` 等于 "active"
- **Then**: 验证 `activeReason` 字段是否不为空

