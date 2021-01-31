{ ---------- GLOBAL CONSTANTS AND VARIABLES ---------------------------------------------------------------------- }


10 Constant Update-Timer                                { Sets windows update rate - lower = faster refresh        }

variable bmp-x-size                                     { x dimension of bmp file                                  }

variable bmp-y-size                                     { y dimension of bmp file                                  }

variable bmp-size                                       { Total number of bmp elements = (x * y)                   }

variable bmp-address                                    { Stores start address of bmp file # 1                     }

variable bmp-length                                     { Total number of chars in bmp including header block      }

variable bmp-x-start                                    { Initial x position of upper left corner                  }

variable bmp-y-start                                    { Initial y position of upper left corner                  }

variable bmp-window-handle                              { Variable to store the handle used to ID display window   }

variable offset                                         { Memory offset used in bmp pixel adddress examples        }

200 bmp-x-size !                                        { Set default x size of bmp in pixels                      }

200 bmp-y-size !                                        { Set y default size of bmp in pixels                      }

bmp-x-size @ 4 / 1 max 4 *  bmp-x-size !                { Trim x-size to integer product of 4                      }

bmp-x-size @ bmp-y-size @ * bmp-size !                  { Find number of pixels in bmp                             }

bmp-size   @ 3 * 54 +       bmp-length !                { Find length of bmp in chars inc. header                  }

100 bmp-x-start !                                       { Set x position of upper left corner                      }

100 bmp-y-start !                                       { Set y position of upper left corner                      }

: bmp-Wind-Name Z" BMP Display " ;                      { Set capion of the display window # 1                     }


{ ----------  RANDOM NUMBER -------------------------------------------------------------------------------------- }


CREATE SEED  123475689 ,

: Rnd ( n -- rnd )                               { Returns single random number less than n }
   SEED                                          { Minimal version of SwiftForth Rnd.f      }
   DUP >R                                        { Algorithm Rick VanNorman rvn@forth.com   }
   @ 127773 /MOD
   2836 * SWAP 16807 *
   2DUP > IF -
   ELSE - 2147483647 +
   THEN  DUP R> !
   SWAP MOD ;


{ ---------- WORDS TO CREATE A BMP FILE IN MEMORY  ---------------------------------------- }


: Make-Memory-bmp  ( x y  -- addr )         { Create 24 bit (RGB) bitmap in memory          }
  0 Locals| bmp-addr y-size x-size |
  x-size y-size * 3 * 54 +                  { Find number of bytes required for bmp file    }
  chars allocate                            { Allocate  memory = 3 x size + header in chars }
  drop to bmp-addr
  bmp-addr                                  { Set initial bmp pixels and header to zero     }
  x-size y-size * 3 * 54 + 0 fill

  { Create the 54 byte .bmp file header block }

  66 bmp-addr  0 + c!                       { Create header entries - B                     }
  77 bmp-addr  1 + c!                       { Create header entries - M                     }
  54 bmp-addr 10 + c!                       { Header length of 54 characters                }
  40 bmp-addr 14 + c!
   1 bmp-addr 26 + c!
  24 bmp-addr 28 + c!                       { Set bmp bit depth to 24                       }
  48 bmp-addr 34 + c!
 117 bmp-addr 35 + c!
  19 bmp-addr 38 + c!
  11 bmp-addr 39 + c!
  19 bmp-addr 42 + c!
  11 bmp-addr 43 + c!

  x-size y-size * 3 * 54 +                  { Store file length in header as 32 bit Dword   }
  bmp-addr 2 + !
  x-size                                    { Store bmp x dimension in header               }
  bmp-addr 18 + !
  y-size                                    { Store bmp y dimension in header               }
  bmp-addr 22 + !
  bmp-addr                                  { Leave bmp start address on stack and exit     }
  ;


{ ---------------------------------- STAND ALONE TEST ROUTINES ---------------------------- }


 : Setup-Test-Memory  ( -- )                        { Create bmps in memory to start with   }
   bmp-x-size @ bmp-y-size @ make-memory-bmp
   bmp-address !
   cr ." Created Test bmp " cr
   ;


{ --------------------------- WORDS TO COLOR BMP PIXELS ------------------------------------}


: Reset-bmp-Pixels  ( addr -- )     { Set all color elements of bmp at addr to zero = black }
  dup 54 + swap
  2 + @ 54 - 0 fill
  ;


: Random-bmp-Green  ( addr -- )           { Set bmp starting at addr to random green pixels }
  dup dup 2 + @ + swap 54 + do
  000                                     { Red   RGB value                                 }
  255 RND                                 { Green RGB value                                 }
  000                                     { Blue  RGB value                                 }
  i  tuck c!
  1+ tuck c!
  1+      c!
  3 +loop
  ;


: Random-bmp-Blue  ( addr -- )             { Set bmp starting at addr to random blue pixels }
  dup dup 2 + @ + swap 54 + do
  000                                      { Red   RGB value                                }
  000                                      { Green RGB value                                }
  255 RND                                  { Blue  RGB value                                }
  i  tuck c!
  1+ tuck c!
  1+      c!
  3 +loop
  ;


{ -------------------- Word to display a bmp using MS Windows API Calls -----------------  }
{                                                                                          }
{ Warning, this section contains MS Windows specific code to create and communicate with a }
{ new display window and will not automatically translate to another OS, e.g. Mac or Linux }


Function: SetDIBitsToDevice ( a b c d e f g h i j k l -- res )


: MEM-bmp ( addr -- )                            { Prints bmp starting at address to screen}
   [OBJECTS BITMAP MAKES BM OBJECTS]
   BM bmp!
   HWND GetDC ( hDC )
   DUP >R ( hDC ) 1 1 ( x y )                         { (x,y) upper right corner of bitmap }
   BM Width @ BM Height @ 0 0 0
   BM Height @ BM Data
   BM InfoHeader DIB_RGB_COLORS SetDIBitsToDevice DROP  { Windows API calls                }
   HWND R> ( hDC ) ReleaseDC DROP ;


{ ---------------------- bmp Display Window Class and Application ------------------------ }
{                                                                                          }
{ Warning, this section contains MS Windows specific code to create and communicate with a }
{ new display window and will not automatically translate to another OS, e.g. Mac or Linux }


0 VALUE bmp-hApp                  { Variable to hold handle for default bmp display window }


: bmp-Classname Z" Show-bmp" ;               { Classname for the bmp output class          }


: bmp-End-App ( -- res )
   'MAIN @ [ HERE CODE> ] LITERAL < IF ( not an application yet )
      0 TO bmp-hApp
   ELSE ( is an application )
      0 PostQuitMessage DROP
   THEN 0 ;


[SWITCH bmp-App-Messages DEFWINPROC ( msg -- res ) WM_DESTROY RUNS bmp-End-App SWITCH]


:NONAME ( -- res ) MSG LOWORD bmp-App-Messages ; 4 CB: bmp-APP-WNDPROC { Link window messages to process }


: bmp-APP-CLASS ( -- )
      0  CS_OWNDC   OR                  \ Allocates unique device context for each window in class
         CS_HREDRAW OR                  \ Window to be redrawn if movement / size changes width
         CS_VREDRAW OR                  \ Window to be redrawn if movement / size changes height
      bmp-APP-WNDPROC                   \ wndproc
      0                                 \ class extra
      0                                 \ window extra
      HINST                             \ hinstance
      HINST 101  LoadIcon
   \   NULL IDC_ARROW LoadCursor        \ Default Arrow Cursor
      NULL IDC_CROSS LoadCursor         \ Cross cursor
      WHITE_BRUSH GetStockObject        \
      0                                 \ no menu
      bmp-Classname                     \ class name
   DefineClass DROP
  ;


: bmp-window-shutdown     { Close bmp display window and unregister classes on shutdown   }
   bmp-hApp IF
   bmp-hApp WM_CLOSE 0 0 SendMessage DROP
   THEN
   bmp-Classname HINST UnregisterClass DROP
  ;


bmp-APP-CLASS                   { Call class for displaying bmp's in a child window     }

13 IMPORT: StretchDIBits

11 IMPORT: SetDIBitsToDevice


{ ----------------------------- bmp Window Output Routines -------------------------------- }
{                                                                                           }
{  Create a new "copy" or "stretch" window, save its handle, and then output a .bmp from    }
{  memory to the window in "copy" mode or "stretch" mode.  You will need to write your own  }
{  data to the .bmp between each display cycle to give a real time view of your simulation. }


: New-bmp-Window-Copy  ( -- res )            \ Window class for "copy" display
   0                                         \ exended style
   bmp-Classname                             \ class name
   s" BMP Window " pad zplace                \ window title - including bmp number
   1  (.) pad zappend pad
   WS_OVERLAPPEDWINDOW                       \ window style
   bmp-x-start @ bmp-y-start @               \ x   y Window position
   bmp-x-size @ 19 + bmp-y-size @ 51 +       \ cx cy Window size
   0                                         \ parent window
   0                                         \ menu
   HINST                                     \ instance handle
   0                                         \ creation parameters
   CreateWindowEx
   DUP 0= ABORT" create window failed"
   DUP 1 ShowWindow DROP
   DUP UpdateWindow DROP
   ;


: New-bmp-Window-Stretch  ( -- res )         \ Window class for "stretch" display
   0                                         \ exended style
   bmp-Classname                             \ class name
   s" BMP Window " pad zplace                \ window title - including bmp number
   1  (.) pad zappend pad
   WS_OVERLAPPEDWINDOW                       \ window style
   bmp-x-start @ bmp-y-start @               \ x   y Window position
   bmp-x-size @ 250 max 10 +
   bmp-y-size @ 250 max 49 +                 \ cx cy Window size, min start size 250x250
   0                                         \ parent window
   0                                         \ menu
   HINST                                     \ instance handle
   0                                         \ creation parameters
   CreateWindowEx
   DUP 0= ABORT" create window failed"
   DUP 1 ShowWindow DROP
   DUP UpdateWindow DROP
   ;


: bmp-to-screen-copy  ( n -- )            { Writes bmp at address to window with hwnd   }
  bmp-window-handle @ GetDC               { handle of device context we want to draw in }
  2 2                                     { x , y of upper-left corner of dest. rect.   }
  bmp-x-size @ 3 -  bmp-y-size @          { width , height of source rectangle          }
  0 0                                     { x , y coord of source rectangle lower left  }
  0                                       { First scan line in the array                }
  bmp-y-size @                            { number of scan lines                        }
  bmp-address @ dup 54 + swap 14 +        { address of bitmap bits, bitmap header       }
  0
  SetDIBitsToDevice drop
  ;


: bmp-to-screen-stretch  ( n addr -- )    { Stretch bmp at addr to window n             }
  0 0 0
  Locals| bmp-win-hWnd bmp-win-x bmp-win-y bmp-address |
  bmp-window-handle @
  dup to bmp-win-hWnd                     { Handle of device context we want to draw in }
  PAD GetClientRect DROP                  { Get x , y size of window we draw to         }
  PAD @RECT
  to bmp-win-y to bmp-win-x
  drop drop
  bmp-win-hWnd GetDC                      { Get device context of window we draw to     }
  2 2                                     { x , y of upper-left corner of dest. rect.   }
  bmp-win-x 4 - bmp-win-y 4 -             { width, height of destination rectangle      }
  0 0                                     { x , y of upper-left corner of source rect.  }
  bmp-address 18 + @                      { Width of source rectangle                   }
  bmp-address 22 + @                      { Height of source rectangle                  }
  bmp-address dup 54 + swap 14 +          { address of bitmap bits, bitmap header       }
  0                                       { usage                                       }
  13369376                                { raster operation code                       }
  StretchDIBits drop
  ;


{ ----------------------------- Demonstration Routines -------------------------------- }


: go-copy                             { Copy bmp to screen at 1x1 pixel size            }
  cr ." Starting looped copy to window test "
  cr cr
  New-bmp-Window-copy                 { Create new "copy" window                        }
  bmp-window-handle !                 { Store window handle                             }
  50 0 Do                             { Begin update / display loop                     }
  bmp-address @ Random-bmp-Green      { Add random pixels to .bmp in memory             }
  bmp-to-screen-copy                  { Copy .bmp to display window                     }
  100 ms                              { Delay for viewing ease, reduce for higher speed }
  Loop
  bmp-window-handle @ DestroyWindow drop
  cr ." Ending looped copy to window test "
  cr cr
  ;


: go-stretch                          { Draw bmp to screen at variable pixel size       }
  cr ." Starting looped stretch to window test "
  cr cr
  New-bmp-Window-stretch              { Create new "stretch" window                     }
  bmp-window-handle !                 { Store window handle                             }
  Begin	                              { Begin update / display loop                     }
  bmp-address @ Random-bmp-Blue       { Add random pixels to .bmp in memory             }
  bmp-address @ bmp-to-screen-stretch { Stretch .bmp to display window                  }
  100 ms                              { Delay for viewing ease, reduce for higher speed }
  key?                                { Break test loop on key press                    }
  until
  cr ." Ending looped stretch to window test "
  cr cr
  ;


: go-dark                              { Draw bmp to screen at variable pixel size       }
  New-bmp-Window-stretch
  bmp-window-handle !
  bmp-address @ Random-bmp-Blue        { Show random blue pixels for a second            }
  bmp-address @ bmp-to-screen-stretch
  1000 ms
  bmp-address @ Random-bmp-Green       { Show random greenpixels for a second            }
  bmp-address @ bmp-to-screen-stretch
  1000 ms
  bmp-address @ reset-bmp-pixels       { Reset .bmp to all black 0,0,0 RGB values        }
  bmp-address @ bmp-to-screen-stretch
  1000 ms
  bmp-window-handle @ DestroyWindow drop  { Kill of display window                       }
  ;


: paint-pixels                  { Create a blank .bmp and then paint individual pixels   }
  cr ." Starting single pixel paint test " cr
  New-bmp-Window-stretch
  bmp-window-handle !
  bmp-address @ bmp-to-screen-stretch   { Write black bmp to screen }

  10 ms
  54 offset !	                               { Paint 1st corner }
  255 bmp-address @ offset @ + 0 + C!
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 2nd corner }
  54 bmp-x-size @ 1 - 3 * + offset !
  255 bmp-address @ offset @ + 1 + C!
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 3rd corner }
  54 bmp-x-size @ 1 - bmp-y-size @ * 3 * + offset !
  255 bmp-address @ offset @ + 2 + C!
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 4th corner }
  54 bmp-x-size @ bmp-y-size @ * 1 - 3 * + offset !
  255 bmp-address @ offset @ + 0 + C!
  255 bmp-address @ offset @ + 1 + C!
  255 bmp-address @ offset @ + 2 + C!
  1000 ms bmp-address @ bmp-to-screen-stretch

  1000 ms
  cr ." Ending single pixel paint test "
  bmp-window-handle @ DestroyWindow drop  { Kill of display window                       }
  cr cr
  ;


{ ---------- LIFE ------------------------------------------------------------------------------------------------- }


{ ---------- PRINT TO FILE VARIABLES AND WORDS ------------------------------------------------------------------- }


variable life_data                                                        { Create Variable to hold file id handle }

: make-file                                                               { Create a test file to read / write to  }
  s" C:\Users\tahse\Desktop\Life_Data.dat" r/w create-file drop           { Create the file to path                }
  life_data !                                                             { Store file handle for later use        }
;


: open-file                                                               { Open the file for read/write access    }
  s" C:\Users\tahse\Desktop\Life_Data.dat" r/w open-file drop             { Not needed if we have just created     }
  life_data !                                                             { file.                                  }
;


: close-file                                                              { Close the file pointed to by the file  }
  life_data @                                                             { handle.                                }
  close-file drop
;


: Write-blank-data                                                        { Write an empty line to the file        }
  s"  " life_data @ write-line drop
;


: Write-line-break                                                        { Write a line break to the file         }
  s" " life_data @ write-line drop
;


{ ---------- Setting constants ------------------------------------------------------------------------------------ }


10 constant k_frames		                                        { number of iterations/generations for our simulation }
22 constant n 				           { Life is simulated on a nxn grid, with a frame of 0s making an absorbing boundary }
n n * constant n_cells
2 n + constant m                                { mxm is the total size of our matrix (including boundary), m = n+2 }
m m * constant tot_cells                                      { m must be a multiple of 4 for correct visualisation }


{ ---------- Words to make arrays for the simulation -------------------------------------------------------------- }


: make_array_ran          { makes a matrix initialised with random 1s and 0s in the middle, 0s along the boundaries }
	tot_cells allocate drop
	dup
	tot_cells 0 fill
	n m * m + m do
		n 0 do
			dup
			j i 1 + + + 2 rnd swap c!
		loop
	m +loop
	constant
;


: show_array 		 	{ prints formatted array to console }
	tot_cells 0 do
		dup i
		m mod 0= if cr
		then i + c@ .
	loop
;


: make_array     { makes an array filled with 0s }
	tot_cells allocate drop
	dup
	tot_cells 0 fill constant
;


{ ---------- Initial Pattern Test Options ---------- }


: make_glider
	tot_cells 2 / m 2 / + +
	dup 1 + 1 swap c!      { R }
	dup 1 - 1 swap c!      { L }
	dup m + 1 swap c!      { B }
	dup m - 1 + 1 swap c!  { TR }
	dup m + 1 + 1 swap c!  { BR }
  drop
;


: make_blinker
	tot_cells 2 / m 2 / + +
	dup 1 swap c!      { C }
	dup 1 + 1 swap c!  { R }
	dup 1 - 1 swap c!  { L }
	dup 2 + 1 swap c!  { 2R }
	dup 2 - 1 swap c!  { 2L }
  drop
;


: make_still_pattern
	tot_cells 2 / m 2 / + +
	dup 1 + 1 swap c!   { R }
	dup 1 - 1 swap c!   { L }
	dup m + 1 swap c!   { B }
	dup m - 1 swap c!   { T }
  drop
;


{ ---------- Creating the matrices and variables ------------------------------------------------------------------------------------------ }


make_array life_matrix              { creates initial main life matrix of 0 }
life_matrix make_glider             { <--- choose initial pattern }
make_array last_state			          { created dummy matrix to store a copy of the last state of main life matrix }
variable count				              { variable to loop through life_matrix when assigning values to the pixels in set-bmp-data }
variable sum			                	{ variable to store the sum of neighbouring cells, used in neigh_sum and update_life }
variable current_cell		           	{ variable to loop through life_matrix cells to update them }
variable last_state_current_cell	  { variable to loop through last_state to determine the sum of neighbouring cells in the last state }


{ ---------- Words to run the core of LIFE ------------------------------------------------------------------------------------------------ }


: neigh_sum			{ computing the sum of neighbouring cells to be used in update_life }

	dup 1 + c@ sum @ + sum !  { R, right }
	dup 1 - c@ sum @ + sum !  { L, left }
	dup m - c@ sum @ + sum !  { T, top }
	dup m + c@ sum @ + sum !  { B, bottom }
	dup m - 1 - c@ sum @ + sum !  { TL }
	dup m - 1 + c@ sum @ + sum !  { TR }
	dup m + 1 - c@ sum @ + sum !  { BL }
	dup m + 1 + c@ sum @ + sum !  { BR }
;


: update_life		                                               	{ updates life_matrix using the rules of LIFE }

	tot_cells 0 do		                                           	{ copy life_matrix into last_state to record the previous configuration }
		life_matrix i + c@ last_state i + c!
	loop

	n m * m + m do	                                          		{ looping through the nxn grid for LIFE and ignoring the frame }
		n 0 do
			0 sum !
			life_matrix j i 1 + + + current_cell !                    { updating current_cell and last_state_current_cell }
			last_state j i 1 + + + last_state_current_cell !
			last_state_current_cell @ neigh_sum	                    	{ calculating sum of neighbours based on last_state }

		  { --- Applying rules of LIFE --- }

			current_cell @ c@ 1 = if
				sum @ 2 <> sum @ 3 <> AND if                            { Rules for death }
					0 current_cell @ c!
				then
			then
			current_cell @ c@ 0 = if
				sum @ 3 = if                                            { Rules for birth }
					1 current_cell @ c!
				then
			then
			drop

		loop
	m +loop
;


{ ---------- Words to display/print the configurations -------------------------- }


: set-bmp-data  ( addr -- )                { Set bmp to the values of life_matrix }
  update_life
  dup dup 2 + @ + swap 54 + do
  life_matrix count @ + c@ 255 *           { Red   RGB value  }
  dup                          	           { Green RGB value  }
  dup                                      { Blue  RGB value  }
  count @ 1 + count !
  i  tuck c!
  1+ tuck c!
  1+      c!
  3 +loop
;


: print_matrix			                       { Printing LIFE matrices to data file }
	tot_cells 0 do
		dup
		i m mod 0= if Write-line-break then
		i + c@ (.) life_data @ write-file drop
	loop
	Write-line-break
;


: print_mnk			                          { printing constants m n k to data file }
	n (.) life_data @ write-file drop
	s"  = n (matrix dimension) "     life_data @ write-line drop
	m (.) life_data @ write-file drop
	s"  = m (matrix + buffer dimension) "     life_data @ write-line drop
 	k_frames (.) life_data @ write-file drop
	s"  = k (total number of frames)"     life_data @ write-line drop
	Write-line-break
;


{ ---------- MAIN word ---------------------------------------------------------------- }


: main
make-file
print_mnk
New-bmp-Window-stretch
bmp-window-handle !
k_frames 0 do dup
	0 count !
  life_matrix
  print_matrix
	bmp-address @ set-bmp-data
	bmp-address @ bmp-to-screen-stretch
	1000 ms
  drop drop
loop
bmp-window-handle @ DestroyWindow drop  { Kill of display window                       }
close-file
cr ." Test ascii data file written to specified path "
cr ." If you are unable to locate file, please check specified path"
cr
;


{ -------- setting up memory and calling the main function ---------- }


m bmp-x-size !    { Create a blank mxm .bmp in memory    }
m bmp-y-size !
Setup-Test-Memory

main
