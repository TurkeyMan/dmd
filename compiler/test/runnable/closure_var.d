/* REQUIRED_ARGS: -betterC
   PERMUTE_ARGS: -O -inline -release -g
 */

/* A nested function that references exactly one variable of the enclosing
 * frame, where that variable fits in a pointer and is never changed after it
 * is initialized, gets the variable's value as its context pointer instead of
 * a frame pointer. No closure is allocated, which -betterC verifies: a closure
 * allocation is a compile error.
 */

struct S { int v = 7; }

enum E : ubyte { a = 3, b = 200 }

int delegate() capturePtr(S* p) @nogc { return () => p.v; }
int delegate() captureInt(int i) @nogc { return () => i + 1; }
int delegate() captureConst(int a) @nogc { const int k = a * 2; return () => k; }
int delegate() captureLocal(int a) @nogc { int k = a * 2; return () => k; }   // never written after init
int delegate() captureBool(bool b) @nogc { return () => b ? 1 : 0; }
int delegate() captureEnum(E e) @nogc { return () => e; }
int delegate() captureChar(char c) @nogc { return () => c; }
int delegate() captureShort(short s) @nogc { return () => s; }
int delegate() captureUint(uint u) @nogc { return () => cast(int) u; }
int delegate() captureFuncPtr(int function() @nogc fp) @nogc { return () => fp(); }

// sibling nested functions both using the same variable
int delegate() siblings(S* p) @nogc
{
    int a() { return p.v; }
    int b() { return a() * 2; }
    return &b;
}

// a function nested in the lambda uses the variable too
int delegate() deeper(S* p) @nogc
{
    return () { int q() { return p.v; } return q() + 1; };
}

// the lambda and a sibling each using a different variable; only the lambda escapes
int delegate() mixed(int k) @nogc
{
    int g() { return k; }
    const int j = g() * 3;
    return () => j + 1;
}

// a sibling that uses nothing itself but calls one that does
int delegate() forwards(S* p) @nogc
{
    int a() { return p.v; }
    int b() { return a() + 1; }
    return &b;
}

// in a member function, capturing a parameter rather than `this`
struct M
{
    int w = 100;
    int delegate() byParam(S* p) @nogc { return () => p.v; }
    int delegate() byThis() @nogc { return () => w; }
}

// the variable is read-only, but only after the delegate is created: that is fine,
// it is never written at all
int delegate() readLater(S* p) @nogc
{
    auto dg = () => p.v;
    assert(p.v == 7);
    return dg;
}

// each iteration declares its own element variable, so each delegate gets its own value
void perIteration() @nogc
{
    static immutable int[3] arr = [10, 20, 30];
    int delegate() @nogc[3] dgs = void;
    foreach (i, v; arr)
        dgs[i] = () => v;
    assert(dgs[0]() == 10 && dgs[1]() == 20 && dgs[2]() == 30);
}

int seven() @nogc { return 7; }

// a local function pointer: the delegate's context is the function pointer itself
int delegate() @nogc localFuncPtr() @nogc
{
    int function() @nogc f = &seven;
    int delegate() @nogc dg;
    dg = () => f();
    assert(dg.ptr is cast(void*) &seven);
    return dg;
}

extern (C) void main()
{
    S s;
    assert(capturePtr(&s)() == 7);
    assert(captureInt(41)() == 42);
    assert(captureConst(21)() == 42);
    assert(captureLocal(21)() == 42);
    assert(captureBool(true)() == 1);
    assert(captureBool(false)() == 0);
    assert(captureEnum(E.b)() == 200);
    assert(captureChar('x')() == 'x');
    assert(captureShort(-5)() == -5);
    assert(captureShort(short.min)() == short.min);
    assert(captureInt(-2)() == -1);
    assert(captureInt(int.min)() == int.min + 1);
    assert(captureUint(uint.max)() == -1);
    assert(captureFuncPtr(&seven)() == 7);
    assert(siblings(&s)() == 14);
    assert(deeper(&s)() == 8);
    assert(mixed(2)() == 7);
    assert(forwards(&s)() == 8);
    M m;
    assert(m.byParam(&s)() == 7);
    assert(m.byThis()() == 100);
    assert(readLater(&s)() == 7);
    perIteration();
    assert(localFuncPtr()() == 7);

    // the delegate's context is the captured value itself
    auto dg = capturePtr(&s);
    assert(dg.ptr is &s);
    s.v = 9;
    assert(dg() == 9);
    assert(captureInt(5).ptr is cast(void*) 5);
}
