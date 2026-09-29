/*
DFLAGS:
REQUIRED_ARGS: -betterC
EXTRA_SOURCES: extra-files/classinfo_layout/object.d
RUN_OUTPUT:
---
classinfo_layout.C depth=4
~B
~A
done
---
*/

// The ClassInfo is whatever object.d's `ClassInfoOf!T()` builds, so a custom
// runtime can define its own representation.

extern (C) int printf(const char*, ...);

interface I
{
    int f();
}

struct Extra
{
    int tag;
}

class A
{
    static immutable Extra __classData = Extra(1);
    ~this() { printf("~A\n"); }
}

class B : A, I
{
    static immutable Extra __classData = Extra(2);
    int f() { return 42; }
    ~this() { printf("~B\n"); }
}

class C : B
{
}

abstract class Abstract
{
    int* p;
    abstract void f();
}

// what the runtime does with it

extern (C) void _d_callfinalizer(void* p)
{
    if (!p)
        return;
    auto ci = *cast(TypeInfo_Class*)*cast(void**)p;
    for (auto c = ci; c; c = c.base)
    {
        if (c.destructor)
            (cast(void function(Object))c.destructor)(cast(Object)p);
    }
}

bool isBaseOf(TypeInfo_Class base, TypeInfo_Class ci)
{
    for (; ci; ci = ci.base)
    {
        if (ci is base)
            return true;
    }
    return false;
}

extern (C) int main()
{
    {
        scope C c = new C;
        auto ci = c.classinfo;
        assert(ci is C.classinfo);
        printf("%.*s depth=%d\n", cast(int)ci.name.length, ci.name.ptr, ci.depth);

        // base chain
        assert(ci.base is B.classinfo);
        assert(ci.base.base is A.classinfo);
        assert(ci.base.base.base is Object.classinfo);
        assert(Object.classinfo.base is null);
        assert(isBaseOf(A.classinfo, ci));
        assert(!isBaseOf(ci, A.classinfo));
        assert(A.classinfo.depth == 2);   // Object itself counts as 1

        // flags
        assert(ci.flags & ClassInfo.Flags.hasDtor);
        assert(!(Object.classinfo.flags & ClassInfo.Flags.hasDtor));
        assert(ci.flags & ClassInfo.Flags.noPointers);
        assert(!(Abstract.classinfo.flags & ClassInfo.Flags.noPointers));
        assert(Abstract.classinfo.flags & ClassInfo.Flags.isAbstract);
        assert(!(ci.flags & ClassInfo.Flags.isAbstract));
        assert(ClassInfo.Flags.sizeof == 1);

        // interfaces
        assert(ci.numInterfaces == 0);
        assert(B.classinfo.numInterfaces == 1);
        assert(ci.interfaces.length == 0);
        assert(B.classinfo.interfaces.length == 1);
        auto iface = B.classinfo.interfaces[0];
        assert(iface.classinfo is I.classinfo);
        I i = c;
        assert(i.f() == 42);
        assert(cast(void*)i - iface.offset is cast(void*)c);

        // destructor chain
        assert(ci.destructor is null);
        assert(B.classinfo.destructor !is null);
        assert(A.classinfo.destructor !is null);

        // hierarchy specific data
        assert((cast(const(Extra)*)A.classinfo.userData).tag == 1);
        assert((cast(const(Extra)*)B.classinfo.userData).tag == 2);
        assert((cast(const(Extra)*)ci.userData).tag == 2);         // inherited from B
        assert(Abstract.classinfo.userData is null);
    }
    printf("done\n");
    return 0;
}
