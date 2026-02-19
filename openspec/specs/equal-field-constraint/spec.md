# equal-field-constraint Specification

## Purpose
TBD - created by archiving change add-equal-field-macro-and-when-property. Update Purpose after archive.
## Requirements
### Requirement: Equal Field Constraint

The `@EqualField` macro MUST be available to validate that two fields have equal values. It SHALL support a `field` property to specify the target field for comparison.

#### Scenario: Basic equal field validation
- **Given**: 一个类有一个字段 `password` 和一个字段 `confirmPassword`
- **When**: `password` 和 `confirmPassword` 的值不相等
- **Then**: 抛出 `JoyValidationException` 异常

