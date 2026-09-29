module object;

// A minimal runtime with its own idea of what a ClassInfo is.
// The compiler emits whatever `ClassInfoOf!T()` builds, and only appends the
// Interface[] array (and the interface vtbls) right after it.

alias size_t = typeof(int.sizeof);
alias string = immutable(char)[];

class Object
{
}

class TypeInfo
{
}

struct Interface
{
    TypeInfo_Class classinfo;
    void*[] vtbl;
    size_t offset;
}

class TypeInfo_Class : TypeInfo
{
    TypeInfo_Class base;
    void* destructor;

    // only the flags this runtime cares about, packed into a byte
    enum Flags : ubyte
    {
        none = 0,
        hasDtor = 1,
        isAbstract = 2,
        noPointers = 4,
    }
    Flags flags;

    // just the count; the Interface[] array immediately follows the ClassInfo
    ubyte numInterfaces;

    ushort depth;
    string name;

    // hierarchy specific data, from a `__classData` member of the class
    immutable(void)* userData;

    const(Interface)[] interfaces() const
    {
        auto p = cast(const(Interface)*)(cast(const(void)*)this + __traits(classInstanceSize, TypeInfo_Class));
        return p[0 .. numInterfaces];
    }
}

alias ClassInfo = TypeInfo_Class;

private template depthOf(T)
{
    static if (is(T S == super) && S.length && is(S[0] == class))
        enum ushort depthOf = cast(ushort)(1 + depthOf!(S[0]));
    else
        enum ushort depthOf = 1;
}

TypeInfo_Class ClassInfoOf(T)()
{
    auto ci = new TypeInfo_Class;
    ci.name = __traits(fullyQualifiedName, T);
    static if (is(T == class))
    {
        static if (is(T S == super) && S.length && is(S[0] == class))
            ci.base = S[0].classinfo;
        static if (__traits(hasMember, T, "__xdtor") && __traits(isSame, __traits(parent, T.__xdtor), T))
            ci.destructor = cast(void*) &T.__xdtor;
        static if (__traits(hasMember, T, "__xdtor"))
            ci.flags |= TypeInfo_Class.Flags.hasDtor;
        static if (__traits(isAbstractClass, T))
            ci.flags |= TypeInfo_Class.Flags.isAbstract;
        enum bitmap = __traits(getPointerBitmap, T);
        static if (bitmap[1 .. $] == size_t[bitmap.length - 1].init)
            ci.flags |= TypeInfo_Class.Flags.noPointers;
        ci.depth = depthOf!T;
        static if (__traits(hasMember, T, "__classData"))
            ci.userData = &T.__classData;
    }
    ci.numInterfaces = cast(ubyte) __traits(getInterfaces, T).length;
    return ci;
}
