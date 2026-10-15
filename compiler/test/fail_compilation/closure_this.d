/*
TEST_OUTPUT:
---
fail_compilation/closure_this.d(14): Error: function `closure_this.S.both` is `@nogc` yet allocates closure for `both()` with the GC
fail_compilation/closure_this.d(14):        delegate `() => this.x + local` closes over variable `this`
fail_compilation/closure_this.d(17): Error: function `closure_this.S.two` is `@nogc` yet allocates closure for `two()` with the GC
fail_compilation/closure_this.d(20):        delegate `() => local` closes over variable `local`
fail_compilation/closure_this.d(17):        `local` declared here
---
*/
struct S
{
    int x;
    int delegate() both(int local) @nogc { return () => x + local; }

    // the this-only lambda is fine, the other one still needs a closure
    void two(int local) @nogc
    {
        int delegate() a = () => x;
        int delegate() b = () => local;
    }

    // no closure: only `this` is captured
    int delegate() ok() @nogc { return () => x; }
}
