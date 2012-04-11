;An alternative floating point implementation
;This one follows the IEEE 754 standard by having the format:
; Sign|Exponent|Significand
;    1          5              10

SET PC, test

:makehalf16	; A = makehalf(A)
	SET PUSH, I
	SET PUSH, J
	SET PUSH, Z
	
	;body
	;sign bit first
	SHL A, 1
	SET Z, O
	SHR A, 1
	IFE Z, 1
		JSR negate16
	
	SET I, 0
	:makehalfloop
		ADD I, 1
		SHL A, 1
		IFN O, 1
			SET PC, makehalfloop
	
	;final assembly of the bits
	SET J, 31
	SUB J, I
	SHL J, 10
	SHL Z, 15
	SHR A, 6
	ADD A, J
	ADD A, Z
	
	;end
	SET Z, POP
	SET J, POP
	SET I, POP
	SET PC, POP

:negate16
;negate A in two's complement
	XOR A, 0xffff
	ADD A, 0x1
	SET PC, POP

:addhalf		; A = addhalf(A, B)
	SET PUSH, B
	SET PUSH, C
	SET PUSH, I
	SET PUSH, J
	SET PUSH, X
	SET PUSH, Y
	SET PUSH, Z
	
	
	;body
	;assume positive for now
		
	SET I, A
	SHR I, 15
	
	SET J, B
	SHR J, 15
	
	AND A, 0x7FFF
	AND B, 0x7FFF
	IFG B, A
		JSR swap
		
	SHR A, 10
	SET X, O
	SHR X, 1
	ADD X, 0x8000
	
	SHR B, 10
	SET Y, O 
	SHR Y, 1
	ADD Y, 0x8000

	;X and Y now contain the mantissa of A and B, respectively
	;A and B now contain their previous exponentS.
	;I and J now contain the sign bits of the original A and B, respectively
	
	SET C, A
	SUB C, B ;C contains difference in exponents
	
	;bring B to the same exponent as A
	SHR Y, C
	
	IFE I, 1
		SET PC, case1
	IFE J, 1
		SET PC, subtraction
	SET PC, addition
	
	:case1
		SET Z, 0x8000	;Make the result to be negative
		IFE J, 0
			SET PC, subtraction ;SUBTRACT if b is positive
		SET PC, addition
	
		
	;then add
	:addition
		ADD X, Y
		IFE O, 1
			SET PC, addhalfoverflow ;overflow occurred, don't shift
		SHL X, 1
		SET PC, addhalfendbranch
	
		:addhalfoverflow
		ADD A, 1
	
	;or subtract
	:subtraction
		SUB X, Y
		JSR scanforone

	;endif
	:addhalfendbranch ;X now contains the significant
	SHL A, 10
	SHR X, 6
	ADD A, X
	ADD A, Z	;replace the sign bit
	;result now in A
	
	;end
	SET Z, POP
	SET Y, POP
	SET X, POP
	SET J, POP
	SET I, POP
	SET C, POP
	SET B, POP
	SET PC, POP
	
:swap	;swap(A, B)
	SET PUSH, C
	SET C, A
	SET A, B
	SET B, C
	SET C, POP
	SET PC, POP

:scanforone
	;first argument (the exponent) on the stack
	:loopscanforone
	SHL X, 1
	IFE O, 1
		SET PC, loopendscanforone
	SUB A, 1
	SET PC, loopscanforone
	
	:loopendscanforone
	SET PC, POP
	
:subhalf 		;A = subhalf(A, B) = A - B
	SET PUSH, B
	XOR B, 0x8000
	JSR addhalf
	SET B, POP
	SET PC, POP
	

:mulhalf		;A = mulhalf(A, B) = A * B
	SET PUSH, B
	SET PUSH, C
	SET PUSH, X
	SET PUSH, Y
	SET PUSH, Z
	SET PUSH, I
	SET PUSH, J
	
	SHR A, 10
	SET X, O
	SHR X, 1
	ADD X, 0x8000
	
	SHR B, 10
	SET Y, O
	SHR Y, 1
	ADD Y, 0x8000
	
	SET C, A
	XOR C, B
	AND C, 0x0020
	
	;A and B now contain the exponents
	;X and Y now contain the mantissas
	;C now contains the sign of the product
	
	;add the exponents
	ADD A, B
	SUB A, 15
	XOR A, 0
	ADD A, C
	
	;multiply the mantissas
	SET Z, 0	;for overflow
	SET C, A	;for result
	
	SET I, 15
	SET B, 0
	:mulhalfloop
		SET J, Y
		SHR J, B
		AND J, 1
		MUL J, X
		SHR J, I
		ADD C, J
		ADD Z, O
		SUB I, 1
		ADD B, 1
		IFN I, 0
			SET PC, mulhalfloop
	
	IFE Z, 0
		SET PC, mulhalfnooverflow
	ADD A, 1
	SET PC, mulhalfend
		
	:mulhalfnooverflow
		SHL C, 1
	
	:mulhalfend
	SHL A, 10
	SHR C, 6
	ADD A, C
	
	SET J, POP
	SET I, POP
	SET Z, POP
	SET Y, POP
	SET X, POP
	SET C, POP
	SET B, POP
	SET PC, POP
	
	
	
;test code
:test

SET A, 0x6505	;0x0505
SET B, 0x4c40	;0x0011

;JSR makehalf16

SET PUSH, A
SET A, B
;JSR makehalf16

SET B, A
SET A, POP

SET PUSH, A
;JSR addhalf
SET X, A
SET A, PEEK

;JSR subhalf
SET Y, A
SET A, PEEK

JSR mulhalf
SET Z, A
SET A, POP

