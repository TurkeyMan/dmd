/*
DFLAGS:
REQUIRED_ARGS: -conf= -betterC
EXTRA_SOURCES: extra-files/classinfo_layout/object.d
TEST_OUTPUT:
---
fail_compilation/classinfo_layout.d(12): Error: class `classinfo_layout.Bad`: `object.ClassInfoOf!(classinfo_layout.Bad)()` must return a `new TypeInfo_Class`, not `NotAClassInfo(null, 0)`
---
*/

class Good { }
class Bad { }       // see also classinfo_layout2.d: no ClassInfo is built once there are errors
