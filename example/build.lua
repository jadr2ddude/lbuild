addcmd("hello.o", {"hello.c"}, {"/usr/bin/cc", "hello.c", "-o", "hello.o"})
addcmd("hello", {}, {"/bin/echo", "hello", "world"})
