/*
DFLAGS:
REQUIRED_ARGS: -conf= -betterC -c -Icompilable/extra-files/ctfe_only_new
*/

// A `@__ctfe` function is never code generated, so its `new` must not be lowered to
// the `_d_newclassT` runtime hook (which this minimal runtime does not have).

class C
{
    int x;
    this(int x) { this.x = x; }
}

int make(int x) @__ctfe
{
    auto c = new C(x);
    return c.x;
}

static assert(make(3) == 3);
