;Floating point operations
;Make a floating point number
SET PC, test

:makefloat	
;(signed integer A)
	
	;body
	SHL A, 1
	SET Z, O ;sign bit
	IFN Z, 1
		set PC, continue
	SHR A, 1
	JSR negate
	SHL A, 1
	
	:continue
	SHL Z, 15 ;put the bit in the first position
	
	
	SET I, 1;
	:loop
	SHL A, 1
	ADD I, 1
	IFN 1, O;
		SET PC, loop
	SHR A, I
	
	;Now check for a too-large integer
	IFG I, 5
		SET PC, smallenough
	SET B, 6
	SUB B, I
	SHR A, B
	SHL A, B
	
	:smallenough
	SHL A, 5
	ADD I, 15
	ADD A, 15
	
	;end

	SET PC, POP

:negate 
;negate A in two's complement
	XOR A, 0xffff
	ADD A, 1
	SET PC, POP
	
	
;Test code
:test
	SET A, 0x0d95
	JSR makefloat