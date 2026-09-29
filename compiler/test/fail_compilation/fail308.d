// REQUIRED_ARGS: -unittest
/*
TEST_OUTPUT:
---
$r:.*object\.d\(\d+\): Error: template instance `object\.\w+!\(MinHeap!\(TestType\).*` recursive expansion$
---
*/

void main()
{
    MinHeap!(int) foo = new MinHeap!(int)();
}

class MinHeap(NodeType)
{
    unittest
    {
        struct TestType {}
        MinHeap!(TestType) foo;
    }
}
