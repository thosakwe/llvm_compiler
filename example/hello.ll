@.str0 private unnamed_addr constant [2 x i8] c"ok\0"

declare i32 @puts (i8* %message);

define i32 @main (i32 %argc, i8** %argv) {
entry:
  %tmp0 = getelementptr [2 x i8], [2 x i8]* %.str0, i8 0
  call i32 @puts (i8* %tmp0)
  ret i32 0
}
