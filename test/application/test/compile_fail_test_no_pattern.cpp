// default expectation is a static assert
template <auto I> struct S {
    static_assert(I != 0);
};

int main() { S<0> s{}; }
