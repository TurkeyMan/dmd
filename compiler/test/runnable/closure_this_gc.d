/* PERMUTE_ARGS: -O -inline -release
 */

/* Nested functions that only use `this` get `this` as their context pointer
 * and allocate no closure, also when mixed with ones that do need a closure.
 */

import core.memory;

struct S
{
    int x = 10;
    int delegate() a, b, c;
    void setup(int local)
    {
        a = () => x;             // context is `this`
        b = () => x + local;     // closure holding `this` and `local`
        c = () => local;         // same closure
    }
}

class C
{
    int v = 7;
    int delegate() keep;
    int delegate() get() { return () => v; }
    void both(int local) { keep = () => v + local; }
    int delegate() viaNamed()
    {
        int bar() { return v + 1; }
        return &bar;
    }
    // the innermost delegate escapes through three levels
    int delegate() threeDeep()
    {
        int delegate() outer()
        {
            int delegate() mid() { return () => v; }
            return mid();
        }
        return outer();
    }
    // `in` contract reads a member: __require uses the frame, the lambda uses `this`
    int delegate() contract()
    in (v > 0)
    {
        return () => v;
    }
}

class D : C
{
    int w = 100;
    override int delegate() get() { return () => super.get()() + w; }
}

// nested struct whose method's lambda reaches a local of the enclosing function
int nestedStruct()
{
    int local = 9;
    struct N
    {
        int v = 1;
        int m() { return (() => v + local)(); }
        int delegate() esc() { return () => v + local; }
    }
    N n;
    auto dg = n.esc();
    return n.m() + dg();
}

// a lambda that only names `this` but instantiates a local struct that captures
// the frame: the struct needs the real frame pointer, so the lambda must get it too
struct LocalAggregate
{
    int x = 10;
    int delegate() f()
    {
        int local = 5;
        struct L { int get() { return local; } }
        return () { L l; return l.get() + x; };
    }
}

void main()
{
    assert(LocalAggregate().f()() == 15);

    S s;
    s.setup(5);
    assert(s.a() == 10 && s.b() == 15 && s.c() == 5);
    s.x = 1;
    assert(s.a() == 1 && s.b() == 6);
    assert(s.a.ptr is &s);
    assert(s.b.ptr !is &s);

    auto c = new C;
    assert(c.get()() == 7);
    assert(c.viaNamed()() == 8);
    assert(c.contract()() == 7);
    assert(c.threeDeep()() == 7);
    c.both(3);
    assert(c.keep() == 10);
    auto d = new D;
    assert(d.get()() == 107);
    C cd = d;
    assert(cd.get()() == 107);

    assert(nestedStruct() == 20);

    // no allocation for the this-only delegate, unlike the real closure
    auto before = GC.stats.allocatedInCurrentThread;
    auto dg = c.get();
    assert(dg.ptr is cast(void*) c);
    auto dg3 = c.threeDeep();
    assert(dg3.ptr is cast(void*) c);
    assert(GC.stats.allocatedInCurrentThread == before);
    c.both(1);
    assert(GC.stats.allocatedInCurrentThread > before);
}
