# Fibonacci Sequence with n = 8
# Register usage: $0: n, $1: f1, $2: f2, $3: 1
# return the value to d255

load:   MOV  $0, 8       # initialize the counter n = 8  | 0011 0000 00001000  | 3008
        MOV  $1, 1       # initialize f1 = 1             | 0011 0001 00000001  | 3101
        MOV  $2, -1      # initialize f2 = -1            | 0011 0010 11111111  | 32FF
        MOV  $3, 1       # load const 1                  | 0011 0011 00000001  | 3301
        MOV  $4, 1       # load const 0                  | 0011 0100 00000000  | 3400
loop:   ADD  $1, $1, $2  # f1 = f1 + f2                  | 0010 0001 0001 0010 | 2112
        SUB  $2, $1, $2  # f2 = f1 - f2                  | 0100 0010 0001 0010 | 4212
        SUB  $0, $0, $3  # n = n - 1                     | 0100 0000 0000 0011 | 4003
        JMPZ $0,  1      # verify if the loop is done    | 0101 0000 00000001  | 5001
        JMPZ $0, -4      # redo the loop                 | 0101 0000 11111011  | 50FB
store:  MOV  d255, $1    # store result in d255          | 0001 0000 11111111  | 10FF