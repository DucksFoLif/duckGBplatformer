INCLUDE "hardware.inc"


SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header


EntryPoint:
    ; Do not turn the LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank
    ; Turn the LCD off
    ld a, 0
    ld [rLCDC], a
    
    ;function that copies memory when loading 
    ;the source of data to register de
    ;the destination in ram to register hl
    ;the size of the copy into register bc 
  ;;
  


; Copy the tile data
ld bc, 4096
ld de, Tileset
ld hl, $9000
call Memcopy

;copying tile map data to the first screen
	ld bc, 1024
	ld de, LevelTilemap
	ld hl, $9800
    call Memcopy


;copying the duck to oam
ld bc, 25
ld de, DuckSprite
ld hl, $8000
call Memcopy


;clearing the OAM to get rid of random garbage;
ld a, 0
ld b, 160
ld hl, _OAMRAM
ClearOam:
ld [hli], a
dec b
jp nz, ClearOam

ld hl, _OAMRAM
ld a, $50
ld [hli], a
ld a, $48
ld [hli], a
ld a, 0
ld [hli], a
ld [hl], a



        ; Turn the LCD on
		ld a, LCDCF_ON | LCDCF_BGON| LCDCF_OBJON 
		ld [rLCDC], a
	
		; During the first (blank) frame, initialize display registers
		ld a, %11100100
		ld [rBGP], a
		ld a, %11100100
		ld [rOBP0], a
	
  
  ;end loop 
      ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wMomentumUp], a
    ld [wMomentumDown], a
    ld a, 1
    ld [wGravity], a
    ld [wSpeedOfScroll], a

    ld a, 6
    ld [wGravityWeakness], a
    
    ld a, 4
    ld [wJumpStrength], a


;setting intial position for screen at 0,0
ld a, $B7  ;12*16 + 7
ld [rSCX], a

;ld a, $40  ;4*16
;ld [rSCY], a
  
Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ; Check the current keys every frame and move left or right.
    call UpdateKeys

;incrimenting frame counter
ld a, [wFrameCounter]
inc a
ld [wFrameCounter], a

;checking to see if player wants to run or not
CheckBButton:
    ld a, [wCurKeys]
    and a, PADF_B

    ;increasing speed if the run button is pressed
    jp nz, IncreaseSpeed
    
;decreasing speed otherwise
DecreaseSpeed:
    ld a, 1
    ld [wSpeedOfScroll], a

    ;continuing to the next position in algorithm
    jp CheckState

;increasing speed 
IncreaseSpeed:
    ld a, 2
    ld [wSpeedOfScroll], a
    jp CheckState


CheckState:
    ;is character jumping? jump to jumping code
    ld a, [wMomentumUp]
    cp a, 0
    jp nz, Jumping

    ;is the character on the ground? jump to movement code
    ld a, [_OAMRAM];loading position of character to compare to y level
    cp $50 ;checking if at ground
    jp z, CheckA ;checking to see if the player wants to jump
    


    ;is character falling? they must be so jump to falling code
    jp Falling
    
    

    

Jumping:
    ;checking if momentum can be changed yet
    ld a, [wFrameCounter]
    ld b, a
    ld a, [wGravityWeakness]
    cp b
    ;goes to this place when momentum cant be changed but character is still jumping
    jp nz, JumpUp

    ;if the result of that comparison is zero it means that momentum can be lowered but movement will still happen
    ;first reset counter now that we can begin to decrease momentum
    ld a, 0
    ld [wFrameCounter], a

    ;next subtract the gravity from momentum
    ld a, [wGravity] ;this modifies how fast the character is jumping, lower values will take smaller amounts of time to slow down the character
    ld b, a
    ld a, [wMomentumUp]
    sub b  ; THIS CAN AND WILL CAUSE AN UNDERFLOW U NEED TO FIX THIS OR ITLL FUCK UP UR CODE ;maybe use a sentinel value here
    ld [wMomentumUp], a

    ;now that gravity has affected momentum we can use the new value of this to jump
    jp JumpUp



JumpUp:
    ld a, [wMomentumUp]
    ld b, a
    ld a, [_OAMRAM]
    sub b
    ld [_OAMRAM], a

    jp CheckXMovement

Falling:
    ;checking if momentum can be changed yet
    ld a, [wFrameCounter]
    ld b, a
    ld a, [wGravityWeakness]
    cp b

    ;goes to this place when momentum cant be changed but character is still jumping
    jp nz, FallDown

    ;if the result of that comparison is zero it means that momentum can be lowered but movement will still happen
    ;first reset counter now that we can begin to increase downwards momentum
    ld a, 0
    ld [wFrameCounter], a

    ;next add the gravity to downwards momentum
    ld a, [wGravity] ;this modifies how fast the character will fall, lower values will take make the character fall slower
    ld b, a
    ld a, [wMomentumDown]
    add b  ; THIS CAN AND WILL CAUSE AN UNDERFLOW U NEED TO FIX THIS OR ITLL FUCK UP UR CODE
    ld [wMomentumDown], a

    ;now that gravity has affected momentum we can use the new value of this to fall
    jp FallDown



FallDown:
    ;this code causes the character to fall
    ld a, [wMomentumDown]
    ld b, a
    ld a, [_OAMRAM]
    add b ; if the result of this causes the player to be lower than ground level, we need to change their height to ground level and cancel their momentum

    ;checking if at ground
    cp $50
    jp nc, CorrectFallDown ;LITERALLY BECAUSE OF THIS ONE VALUE if this is c it will shove u into the ground like super mario land

    ;because position is valid we can load it into the sprites
    ld [_OAMRAM], a

    ;continuing into the loop
    jp CheckXMovement

;this will occur if the current location of the sprite is less than ground level
CorrectFallDown:
    ;resetting height
    ld a, $50
    ld [_OAMRAM], a

    ;resetting falling position
    ld a, 0
    ld [wMomentumDown], a

    jp Main


CheckA:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, CheckLeft
Jump:
    ;changing momentum to have the same value as jump strength
    ld a, [wJumpStrength]
    ld [wMomentumUp], a

    ;starting gravity framecounter
    ld a,0
    ld [wFrameCounter], a
    jp CheckLeft
    

;


CheckXMovement:
    call UpdateKeys
    ; First, check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
     ;flip sprite across the x axis to face the left
    ld a, OAMF_XFLIP
    ld [_OAMRAM + 3], a

    ; Move the paddle one pixel to the left.
    ;ld a, [_OAMRAM + 1]
    ;dec a
    ; If we've already hit the edge of the playfield, don't move.
    ;cp a, 15
    ;jp z, Main
    ;ld [_OAMRAM + 1], a

    ;scrolling screen
    ld a, [wSpeedOfScroll]
    ld b, a
    ld a,[rSCX]
    sub a,b
    ld [rSCX], a

    jp Main

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main
Right:
    ;flip sprite across the x axis to face the right
    ld a, 0
    ld [_OAMRAM + 3], a

    ; Move the paddle one pixel to the right.
    ;ld a, [_OAMRAM + 1]
    ;inc a
    ; If we've already hit the edge of the playfield, don't move.
    ;cp a, 105
    ;jp z, Main
    ;ld [_OAMRAM + 1], a

    ;scrolling screen
    ld a, [wSpeedOfScroll]
    ld b, a
    ld a,[rSCX]
    add a,b
    ld [rSCX], a

    jp Main
    ;end of MAIN loop

  



    ;VARIOUS FUNCTIONS
	UpdateKeys:
	; Poll half the controller
	ld a, P1F_GET_BTN
	call .onenibble
	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons
  
	; Poll the other half
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a ; A3-0 = unpressed directions; A7-4 = 1
	xor a, b ; A = pressed buttons + directions
	ld b, a ; B = pressed buttons + directions
  
	; And release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a
  
	; Combine with previous wCurKeys to make wNewKeys
	ld a, [wCurKeys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret
  
  .onenibble
	ldh [rP1], a ; switch the key matrix
	call .knownret ; burn 10 cycles calling a known ret
	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
  .knownret
	ret
  


Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret
;

SECTION "Game Data", ROM0
Tileset:: INCBIN "h.gb"
LevelTilemap:: INCBIN "level.tilemap"
DuckSprite:: INCBIN "duck.gb"


SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Player Attributes", WRAM0
wMomentumUp : db
wMomentumDown : db
wGravity : db
wSpeedOfScroll : db
wGravityWeakness : db
wJumpStrength : db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db


