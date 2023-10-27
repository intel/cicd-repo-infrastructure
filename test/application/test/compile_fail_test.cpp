// EXPECT: (incomplete type)|(undefined template)

template <typename...> struct S;

int main() { S<float> s{}; }
