/*
TEST_OUTPUT:
---
fail_compilation/closure_var.d(38): Error: function `closure_var.reassigned` is `@nogc` yet allocates closure for `reassigned()` with the GC
fail_compilation/closure_var.d(40):        delegate `() => (*p).v` closes over variable `p`
fail_compilation/closure_var.d(38):        `p` declared here
fail_compilation/closure_var.d(47): Error: function `closure_var.addressTaken` is `@nogc` yet allocates closure for `addressTaken()` with the GC
fail_compilation/closure_var.d(49):        delegate `() => (*p).v` closes over variable `p`
fail_compilation/closure_var.d(47):        `p` declared here
fail_compilation/closure_var.d(56): Error: function `closure_var.passedByRef` is `@nogc` yet allocates closure for `passedByRef()` with the GC
fail_compilation/closure_var.d(58):        delegate `() => (*p).v` closes over variable `p`
fail_compilation/closure_var.d(56):        `p` declared here
fail_compilation/closure_var.d(63): Error: function `closure_var.boundToRef` is `@nogc` yet allocates closure for `boundToRef()` with the GC
fail_compilation/closure_var.d(65):        delegate `() => (*p).v` closes over variable `p`
fail_compilation/closure_var.d(63):        `p` declared here
fail_compilation/closure_var.d(71): Error: function `closure_var.twoVariables` is `@nogc` yet allocates closure for `twoVariables()` with the GC
fail_compilation/closure_var.d(73):        delegate `() => (*p).v + k` closes over variable `p`
fail_compilation/closure_var.d(71):        `p` declared here
fail_compilation/closure_var.d(76): Error: function `closure_var.refParam` is `@nogc` yet allocates closure for `refParam()` with the GC
fail_compilation/closure_var.d(78):        delegate `() => (*p).v` closes over variable `p`
fail_compilation/closure_var.d(76):        `p` declared here
fail_compilation/closure_var.d(81): Error: function `closure_var.byValueStruct` is `@nogc` yet allocates closure for `byValueStruct()` with the GC
fail_compilation/closure_var.d(83):        delegate `() => s.v` closes over variable `s`
fail_compilation/closure_var.d(81):        `s` declared here
fail_compilation/closure_var.d(86): Error: function `closure_var.floating` is `@nogc` yet allocates closure for `floating()` with the GC
fail_compilation/closure_var.d(88):        delegate `() => d` closes over variable `d`
fail_compilation/closure_var.d(86):        `d` declared here
fail_compilation/closure_var.d(97): Error: function `closure_var.reassignedFuncPtr` is `@nogc` yet allocates closure for `reassignedFuncPtr()` with the GC
fail_compilation/closure_var.d(100):        delegate `() { (*f)(); return ; }` closes over variable `f`
fail_compilation/closure_var.d(99):        `f` declared here
---
*/
struct S { int v; }

// A delegate capturing a single pointer-sized variable needs no closure,
// unless the variable may change, or be aliased, after the capture.

int delegate() reassigned(S* p) @nogc
{
    auto dg = () => p.v;
    p = null;
    return dg;
}

void take(S** pp) @nogc {}

int delegate() addressTaken(S* p) @nogc
{
    auto dg = () => p.v;
    take(&p);
    return dg;
}

void modify(ref S* pp) @nogc {}

int delegate() passedByRef(S* p) @nogc
{
    auto dg = () => p.v;
    modify(p);
    return dg;
}

int delegate() boundToRef(S* p) @nogc
{
    auto dg = () => p.v;
    ref S* q = p;
    q = null;
    return dg;
}

int delegate() twoVariables(S* p, int k) @nogc
{
    return () => p.v + k;
}

int delegate() refParam(ref S* p) @nogc
{
    return () => p.v;
}

int delegate() byValueStruct(S s) @nogc
{
    return () => s.v;
}

double delegate() floating(double d) @nogc
{
    return () => d;
}

// but a `const` struct pointer parameter, or one that is never touched, is fine
int delegate() ok(const S* p) @nogc { return () => p.v; }

void one() @nogc {}
void two() @nogc {}

void delegate() reassignedFuncPtr() @nogc
{
    void function() @nogc f = &one;
    auto dg = () => f();
    f = &two;
    return dg;
}
