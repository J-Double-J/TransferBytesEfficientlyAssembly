    .text
    .align 2
    .global MEMCPY

//x0 ptr to destination
//x1 ptr to source
//x2 is length of the copy
MEMCPY: 
    str x30, [sp, -16]!

    mov x19, x0                     //move args to safe registers
    mov x20, x1
    mov x21, x2                   

    //bl trimLeadingBytes             //Get size to be divisible by 32
    bl transferBytes                //Use duff device to transfer
    
    mov x2, x0                      //Length to be passed is the remaining <32 bytes
    mov x0, x19
    mov x1, x20

    cmp x2, xzr                     //if length is now 0
    beq 99f                         //end

    sub x3, x21, x2                 //Original length - remaining length to be trimmed
    add x0, x0, x3                  //Increment dest address by ^
    add x1, x1, x3                  //Increment src address 

    bl trimLastBytes    
    
99: ldr x30, [sp], 16
    mov x0, xzr
    ret

//x0 is dividend, x1 is mod
//Used x register in case of big values
//int modulo(int dividend, int mod)
modulo:
    udiv    x2, x0, x1              //x/y -> integer z
    mul     x2, x2, x1              //z*y = z
    sub     x0, x0, x2              //x - (z*y) = remainder
    ret

//Transfers the up to the first 31 bytes of data
//void transferLeadingBytes(* destination, * source, length)
trimLastBytes:
    str x30, [sp, -16]!
    mov x4, x0                      //move three variables to not be erasesd by modulo call; dest
    mov x5, x1                      //src
    mov w6, w2                      //remainder

19: mov w1, 16
    mov w0, w6
    udiv w0, w0, w1
    cmp w0, 1                       //if divisible by 16
    beq 1f                          //load long

20: mov w1, 8
    mov w0, w6
    udiv w0, w0, w1
    cmp w0, 1                       //if divisible by 8
    beq 2f                          //load long

21: mov w1, 4
    mov w0, w6
    udiv w0, w0, w1
    cmp w0, 1                       //if divisible by 4
    beq 3f                          //load int

22: mov w1, 2
    mov w0, w6
    udiv w0, w0, w1
    cmp w0, 1                       //if divisible by 2
    beq 4f                          //load short

23: mov w1, 1
    mov w0, w6
    udiv w0, w0, w1
    cmp w0, 1                       //if divisible by 1
    beq 5f                          //load short
    b 6f


1:  sub w6, w6, 16                   //shorten length by 16
    ldr q7, [x5], 16                 //increment source address by 16 (does not affect main function's pointer)
    str q7, [x4], 16                 //increment destination by 16 (does not affect main function's pointer)
    b   20b


2:  sub w6, w6, 8                   //shorten length by 8
    ldr x7, [x5], 8                 //increment source address by 8 (does not affect main function's pointer)
    str x7, [x4], 8                 //increment destination by 8 (does not affect main function's pointer)
    b   21b

3:  sub w6, w6, 4                   //shorten length by 4
    ldr w7, [x5], 4                 //increment source address by 4 (does not affect main function's pointer)
    str w7, [x4], 4                 //increment destination by 4 (does not affect main function's pointer)
    b   22b

4:  sub w6, w6, 2                   //shorten length by 2
    ldrh w7, [x5], 2                //increment source address by 2 (does not affect main function's pointer)
    str w7, [x4], 2                 //increment destination by 2 (does not affect main function's pointer)
    b   23b

5:  sub w6, w6, 1                   //shorten length by 1
    ldrb w7, [x5], 1                //increment source address by 1 (does not affect main function's pointer)
    str w7, [x4], 1                 //increment destination by 1 (does not affect main function's pointer)

6:  ldr x30, [sp], 16
    ret

//void transferLeadingBytes(* destination, * source, length)
transferBytes:
    str x30, [sp, -16]!

    mov  w10, 256
    mov  x3, x2
    udiv x3, x3, x10                //loops = (count)/256   x3 is the num of unrolled loops

    mov x4, x0                      //move the three passed variables to safe registers before using modulo func
    mov x5, x1
    mov x6, x2

    mov w10, 256
    mul w7, w3, w10                 //num of loops*256
    sub w6, w6, w7                  //length - (num of loops * 256)

    mov w10, 32
    udiv w11, w6, w10               //num of times ^ is divisible now by 32
    mul w12, w11, w10               //get 32*result 
    sub w6, w6, w12                 //subtract from length
    mov w10, 8
    mul w11, w11, w10               //multiply division result by 8

    mov w10, 64
    ldr x1, =duff
    sub w10, w10, w11               //w10 = 64 - (<int>(length - (num of loops * 256)/32))*8
    add x1, x1, x10
    br  x1



20: cmp w3, wzr                     //if(count == 0)
    beq 21f                         //break
    sub w3, w3, 1                   //--loop
    //every 8 ldp/stp pairs will transfer 256 bytes
duff:ldp q8, q9, [x5], 32            //Load 32 bytes, then post increment
    stp q8, q9, [x4], 32            //Store 32 bytes, then post increment
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32
    ldp q8, q9, [x4], 32
    stp q8, q9, [x5], 32   
    b 20b                           //loop


21: ldr x30, [sp], 16
    mov w0, w6                      //return amount to be trimmed
    ret
