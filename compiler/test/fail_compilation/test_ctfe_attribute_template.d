/*
TEST_OUTPUT:
---
fail_compilation/test_ctfe_attribute_template.d(19): Error: function `test_ctfe_attribute_template.add!int` is `@__ctfe` and cannot be used at runtime
---
*/

// `@__ctfe` on a template function was lost when the declaration was copied for instantiation

T add(T)(T a, T b) @__ctfe
{
    return a + b;
}

enum three = add!int(1, 2);     // fine

void main()
{
    auto x = add!int(1, 2);
}
