
// TODO
//		make chars into 1 byte (as they are) and not 8
//		fix the negative numbers
//		is it possible for the multiplying to mess up the fractal part? no?

// ADD?
//		stdin 12.34
//		constants - pi, e
//		power
//		log

////////

int_syscall = 0x80

code_read = 0x03
code_write = 0x04
code_exit = 0xfc

file_stdin = 0
file_stdout = 1

//////// functions
.text

_start:
	mov $'\n', %rax
	call main
	mov %eax, %r8d
	mov %rbx, %r9
	mov %rcx, %r10
	mov %rdx, %r11

	mov $'=', %rax
	call fn_write_char

	mov %r9, %rax
	call fn_write_int

	mov $0, %rax
	cmp %rax, %r10
	jz no_remainder
	
	mov $'+', %rax
	call fn_write_char

	mov $'(', %rax
	call fn_write_char

	mov %r10, %rax
	call fn_write_int

	mov $'/', %rax
	call fn_write_char

	mov %r11, %rax
	call fn_write_int

	mov $')', %rax
	call fn_write_char
	no_remainder:

	call fn_write_nl

	// convert %r8d to %r8, for the next step
	mov %r8d, %eax
	cltq
	mov %rax, %r8
	
	mov err_msg_len, %rax
	imul %r8, %rax

	lea err_to_str, %rbx
	add %rbx, %rax

	mov err_msg_len, %rbx
	call fn_write_str

	call fn_write_nl

	mov $0, %eax
	cmp %eax, %r8d
	jz no_errors

	// return code
	//mov %r8d, %eax
	//call fn_exit

	no_errors:
	jmp _start



ERR_BAD_OPERATOR = 1
ERR_DIVISION_BY_ZERO = 2

// %rax - the character that marks the end of the equasion
main:

	// the exit character - %rdx
	// first integer X+(a/b)
	push %r8
	// first integer x+(A/b)
	push %r9
	// first integer x+(a/B)
	push %r10
	// first integer operator
	push %r11
	// second integer X+(a/b)
	push %r12
	// second integer x+(A/b)
	push %r13
	// second integer x+(a/B)
	push %r14
	// second integer operator
	push %r15

	mov %rax, %rdx

	// simulate the first input as "(0/1)+"
	mov $0, %r8
	mov $0, %r9
	mov $1, %r10
	mov $'+', %r11
	
	main__check_sign:

	// check the operator, weather its time for us to return	
	cmp %rdx, %r11
	jz main__end_of_equasion

	// then get the second number
	// and the next operator
	call fn_read_int
	mov %rax, %r12
	mov $0, %r13
	mov $1, %r14
	mov %rbx, %r15
	
	// check if the second numbers operator is '('
	mov $'(', %rax
	cmp %rax, %r15
	jnz main__not_an_open_bracket
	
	// if we have a '(', we need to calculate the brackets

	push %rdx
	
	mov $')', %rax
	call main
	mov %rbx, %r12
	mov %rcx, %r13
	mov %rdx, %r14
	
	pop %rdx

	// check if main yielded an error
	mov $0, %ebx
	cmp %ebx, %eax
	
	jz main__nothing_wrong
	// the error code is already in %eax
	jmp main__ret

	main__nothing_wrong:

	// get the operator; the integer should be 0 here
	call fn_read_int
	mov %rbx, %r15
	
	main__not_an_open_bracket:

	mov $'+', %rcx
	cmp %rcx, %r11
	jz main__add

	mov $'-', %rcx
	cmp %rcx, %r11
	jz main__sub

	mov $'*', %rcx
	cmp %rcx, %r11
	jz main__mul

	mov $'/', %rcx
	cmp %rcx, %r11
	jz main__div

	jmp main__invalid_operator


	main__add:
	call fn_add_frac
	jmp main__end
	main__sub:
	call fn_sub_frac
	jmp main__end
	main__mul:
	call fn_mul_frac
	jmp main__end
	
	main__div:

	call fn_div_frac
	jz main__div__no_error
	// if error, the return code has already been set to %rax
	jmp main__ret	
	main__div__no_error:
	jmp main__end
	
	main__invalid_operator:
	mov $ERR_BAD_OPERATOR, %eax
	jmp main__ret
	
	main__end:
	// move the 'next' operator as the 'current' operator
	mov %r15, %r11
	
	jmp main__check_sign

	main__end_of_equasion:

	mov $0, %eax

	main__ret:

	mov %r8, %rbx
	mov %r9, %rcx
	mov %r10, %rdx

	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	ret
// %eax - error code
// %rbx - result
// %rcx - plus ME over %rdx
// %rdx - plus %rcx over ME



// %r8... %r12...
fn_div_frac:
	push %rbx
	push %rcx
	push %rdx

	// check if dividing by 0
	mov %r12, %rax
	or %r13, %rax
	
	mov $0, %rbx
	cmp %rbx, %rax
	jnz fn_div__not_dividing_by_zero

	mov $ERR_DIVISION_BY_ZERO, %eax
	call fn_set_jnz
	jmp fn_div__ret
	
	fn_div__not_dividing_by_zero:

	// a+b/c  //  c+d/e

	// acf
	mov %r8, %rax
	imul %r10, %rax
	imul %r14, %rax

	// bf
	mov %r9, %rbx
	imul %r14, %rbx

	// cdf
	mov %r10, %rcx
	imul %r12, %rcx
	imul %r14, %rcx
	
	// ce
	mov %r10, %rdx
	imul %r13, %rdx

	// acf + bf
	add %rbx, %rax

	// cdf + ce
	mov %rcx, %rbx
	add %rdx, %rbx

	// acf+bf  //  cdf+ce
	xor %rdx, %rdx
	idivq %rbx
	// res - %rax
	// rem - %rdx
	mov %rax, %r8
	mov %rdx, %r9
	mov %rbx, %r10

	call fn_normalise_divisor

	
	// set the return code to 0
	mov $0, %rax
	// set the jump flag
	call fn_set_jz

	fn_div__ret:
	pop %rdx
	pop %rcx
	pop %rbx
	ret
// %eax - error code
// jz - no error
// jnz - error

// %r8... %r12...
fn_mul_frac:
	push %rax
	push %rbx
	push %rcx
	push %rdx
	call fn_sync_divisors

	// r8*r12 + r8*r13 + r9*r12 + r9*r13

	// r8*r12 hole*hole
	mov %r8, %rax
	imul %r12, %rax

	// r8 * r13 hole*frac
	mov %r8, %rbx
	imul %r13, %rbx

	// r9, r12 frac*hole
	mov %r9, %rcx
	imul %r12, %rcx

	// r9, r13 frac*frac
	mov %r9, %rdx
	imul %r13, %rdx

	// the hole part is in %rax -> X/1

	// sum the frac parts -> X/Y
	add %rcx, %rbx

	// the frac^2 -> X/Y^2
	mov %rdx, %rcx

	// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	mov %rax, %r8
	mov %rbx, %r9
	// %r10 stays the same

	mov $0, %r12
	mov %rcx, %r13
	imul %r14, %r14

	call fn_normalise_divisor

	call fn_add_frac

	//call fn_normalise_divisor // fn_add_frac has already normalised
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax
	ret

// %r8... %r12...
fn_sub_frac:
	call fn_sync_divisors

	sub %r12, %r8
	sub %r13, %r9

	cmp %r9, %r10
	ja fn_sub_frac__no_underflow

	sub $1, %r8
	add %r10, %r9

	fn_sub_frac__no_underflow:

	call fn_normalise_divisor
	ret

// a+(b/c) ++ d+(e/f)
// %r8 - a
// %r12 - d
fn_add_frac:
	push %rax
	push %rdx
	call fn_sync_divisors
	// now c == f

	add %r12, %r8
	add %r13, %r9

	xor %rdx, %rdx
	mov %r9, %rax
	divq %r10

	add %rax, %r8
	mov %rdx, %r9

	call fn_normalise_divisor
	pop %rdx
	pop %rax
	ret
// a, b, c - the result



// TODO make this work ~more optimally
// %r9 %r10
fn_normalise_divisor:
	push %rax
	push %rbx
	push %rdx
	// the pointer to the prime
	push %r11
	// the prime
	push %r12
	// %r9, divided
	push %r13
	// %r10, divided
	push %r14

	mov $1, %rax
	cmp %rax, %r10
	jz fn_normalise_divisor__ret

	lea primes, %r11

	fn_normalise_divisor__started_from_the_bottom_now_were_here:

	mov $0, %r12
	mov (%r11), %r12b

	mov $0, %al
	cmp %al, %r12b
	jz fn_normalise_divisor__done_with_the_last_prime

	xor %rdx, %rdx
	mov %r9, %rax
	divq %r12

	mov $0, %rbx
	cmp %rbx, %rdx
	jnz fn_normalise_divisor__not_divisable

	// save the new %r9
	mov %rax, %r13

	// %rdx should already be 0
	mov %r10, %rax
	divq %r12

	mov $0, %rbx
	cmp %rbx, %rdx
	jnz fn_normalise_divisor__not_divisable

	// load tge new %r9
	mov %r13, %r9
	// load the new %r10
	mov %rax, %r10

	jmp fn_normalise_divisor__started_from_the_bottom_now_were_here

	fn_normalise_divisor__not_divisable:

	inc %r11
	jmp fn_normalise_divisor__started_from_the_bottom_now_were_here

	fn_normalise_divisor__done_with_the_last_prime:
	fn_normalise_divisor__ret:

	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %rdx
	pop %rbx
	pop %rax
	ret
// %r9 and %r10 are now normalised

// %r8... %r12...
fn_sync_divisors:
	push %rax
	push %rbx

	mov %r10, %rax
	mov %r14, %rbx

	imul %rbx, %r9
	imul %rbx, %r10

	imul %rax, %r13
	imul %rax, %r14

	pop %rbx
	pop %rax
	ret



fn_read_int:
	push %r8
	push %r9
	
	xor %r8, %r8
	fn_read_int__get_next_int:

	call fn_read_char
	mov %rax, %r9
	call fn_is_int
	jz fn_read_int__not_int

	call fn_char_to_int

	imul $10, %r8
	add %rax, %r8
	
	jmp fn_read_int__get_next_int
	
	fn_read_int__not_int:
	mov %r8, %rax
	mov %r9, %rbx

	pop %r9
	pop %r8
	ret
// %rax - the red integer
// %rbx - the following separator

fn_read_int_len1:
	call fn_read_char
	call fn_char_to_int
	ret
// %rax - the resulting integer

fn_read_char:
	push %rbx
	push tmp_char

	lea tmp_char, %eax
	mov $1, %ebx
	call fn_read_str
	mov tmp_char, %rax

	pop tmp_char
	pop %rbx
	ret
// %rax - the stored character

// %eax - addr - where to write
// %ebx - how much at max ?
fn_read_str:
	push %rax
	push %rbx
	push %rcx
	push %rdx
	
	movl %eax, %ecx
	movl %ebx, %edx
	movl $code_read, %eax
	movl $file_stdin, %ebx
	call fn_syscall
	
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax
	ret



// %rax - the integer
fn_write_int:
	push %rax
	push %rbx
	push %rdx

	mov $9, %rbx
	cmp %rax, %rbx
	jl fn_write_int__more_than_9

	call fn_write_int_len1
	jmp fn_write_int__ret

	fn_write_int__more_than_9:

	mov $10, %rbx
	xor %rdx, %rdx
	idivq %rbx

	call fn_write_int

	mov %rdx, %rax
	call fn_write_int_len1

	fn_write_int__ret:
	pop %rdx
	pop %rbx
	pop %rax
	ret

// %rax - the integer
fn_write_int_len1:
	push %rax
	
	call fn_int_to_char
	call fn_write_char
	
	pop %rax
	ret

fn_write_nl:
	push %rax

	mov $'\n', %rax
	call fn_write_char

	pop %rax
	ret

// %rax - the character
fn_write_char:
	push %rax
	push %rbx
	push tmp_char
	
	mov %rax, tmp_char
	lea tmp_char, %eax
	movl $1, %ebx
	call fn_write_str
	
	pop tmp_char
	pop %rbx
	pop %rax
	ret

// %eax ->addr - the string
// %ebx - the length (AND NOT THE SIZE)
fn_write_str:
	push %rax
	push %rbx
	push %rcx
	push %rdx
	
	movl %eax, %ecx
	movl %ebx, %edx
	movl $code_write, %eax
	movl $file_stdout, %ebx
	call fn_syscall
	
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax
	ret





// %rax - the thing to be tested
fn_is_int:
	push %rax
	push %rbx

	call fn_char_to_int
	mov $10, %rbx
	cmp %rax, %rbx
	ja fn_is_int__yes_its_int
	fn_is_int__no_its_not:
	//cmp %rax, %rax
	call fn_set_jz
	jmp fn_is_int__ret
	fn_is_int__yes_its_int:
	//mov %rax, %rbx
	//add $1, %rbx
	//cmp %rax, %rbx
	call fn_set_jnz
	
	fn_is_int__ret:
	pop %rbx
	pop %rax
	ret
//
//	jnz - if int
//	jz - if not an int

// %rax - the int
fn_int_to_char:
	add $'0', %rax
	ret
// %rax - the resulting char

// %rax - the char
fn_char_to_int:
	sub $'0', %rax
	ret
// %rax - the resulting int



// sets the JZ(jump zero) flag
fn_set_jz:
	cmp %rax, %rax
	ret

// sets the JNZ(jump not zero) flag
fn_set_jnz:
	push %rax

	mov %rbx, %rax
	inc %rax
	cmp %rax, %rbx

	pop %rax
	ret



fn_exit_succ:
	push %rax
	
	movl $0, %eax
	call fn_exit
	
	pop %rax
	ret

fn_exit_fail:
	push %rax
	
	movl $1, %eax
	call fn_exit
	
	pop %rax
	ret

// %eax - the exit code
fn_exit:
	push %rax
	push %rbx
	
	movl %eax, %ebx
	movl $code_exit, %eax
	call fn_syscall
	
	pop %rbx
	pop %rax
	ret

fn_syscall:
	int $int_syscall
	ret



//////// global variables
.data

//tmp_char: .byte 0
//size_char = . -tmp_char
//len_char = . -tmp_char

tmp_char: .zero 8

primes:
	.byte 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 0

err_msg_len:
	.byte 8
	.zero 7
err_to_str:
	.ascii "No error"
	.ascii "Bad oper"
	.ascii "Div by 0"

.globl  _start
