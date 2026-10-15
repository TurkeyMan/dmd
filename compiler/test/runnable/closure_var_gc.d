/* PERMUTE_ARGS: -O -inline -release
 */

/* A nested function capturing a single never-written, pointer-sized variable
 * gets its value as the context pointer and allocates no closure; one that
 * captures a variable which is written afterwards still gets a closure.
 */

import core.memory;

class C { int v = 7; }

int delegate() capture(C c) { return () => c.v; }

int delegate() captureThenReassign(C c)
{
    auto dg = () => c.v;
    c = new C;
    c.v = 8;
    return dg;
}

// each iteration declares its own element variable: one value per delegate
int delegate()[] perIteration(C[] cs)
{
    int delegate()[] dgs;
    foreach (c; cs)
        dgs ~= () => c.v;
    return dgs;
}

void main()
{
    auto c = new C;
    auto before = GC.stats.allocatedInCurrentThread;
    auto dg = capture(c);
    assert(GC.stats.allocatedInCurrentThread == before);
    assert(dg.ptr is cast(void*) c);
    assert(dg() == 7);
    c.v = 9;
    assert(dg() == 9);

    // the variable changes after the delegate is made, so the delegate sees the change
    before = GC.stats.allocatedInCurrentThread;
    auto dg2 = captureThenReassign(c);
    assert(GC.stats.allocatedInCurrentThread > before);
    assert(dg2() == 8);

    auto cs = [new C, new C, new C];
    foreach (i, x; cs)
        x.v = cast(int) i;
    auto dgs = perIteration(cs);
    assert(dgs[0]() == 0 && dgs[1]() == 1 && dgs[2]() == 2);
}
