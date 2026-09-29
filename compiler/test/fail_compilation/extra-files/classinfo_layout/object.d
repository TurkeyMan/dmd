module object;

// A ClassInfoOf that does not build a TypeInfo_Class

alias size_t = typeof(int.sizeof);
alias string = immutable(char)[];

class Object { }
class TypeInfo { }

class TypeInfo_Class : TypeInfo
{
    TypeInfo_Class base;
}

class NotAClassInfo : TypeInfo_Class
{
    int extra;
}

TypeInfo_Class ClassInfoOf(T)()
{
    static if (__traits(identifier, T) == "Bad")
        return new NotAClassInfo;       // a subclass has a different size, which the compiler relies on
    else static if (__traits(identifier, T) == "Worse")
        return null;
    else
        return new TypeInfo_Class;
}
