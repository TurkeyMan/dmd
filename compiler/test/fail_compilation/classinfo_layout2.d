/*
DFLAGS:
REQUIRED_ARGS: -conf= -betterC
EXTRA_SOURCES: extra-files/classinfo_layout/object.d
TEST_OUTPUT:
---
fail_compilation/classinfo_layout2.d(12): Error: class `classinfo_layout2.Worse`: `object.ClassInfoOf!(classinfo_layout2.Worse)()` must return a `new TypeInfo_Class`, not `null`
---
*/

class Good { }
class Worse { }
