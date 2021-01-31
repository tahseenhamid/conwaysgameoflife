## Introduction

This repositry contains 3 files:
1. conwayslife_core.f
2. conwayslife_test_patterns.f
3. conwayslife_phase_transitions.f

Each file can be run independently in the Forth console

Each file has only been tested on SwiftForth on Windows 10

There are some specific instructions for each file

## Conway's Game of Life Rules: Naming Convention

Conway's Game of Life obeys the following rules by default:
1. A cell is born (0 -> 1) if it has 3 live neighbours. This is represented by B3
2. A cell survives (1 -> 1) if it has 2 or 3 neighbours. This is represented by S23
3. Otherwise, a cell dies (1 -> 0)


## 1. Core Code: conwayslife_core.f

The file runs Conway's Game of Life on an initial matrix of random 1s and 0s

To use this file:
1. Set grid size by setting n on line 422 (22 by default). Note that n+2 must be a multiple of 4
2. Set number of generations to be run by setting k on line 421 (10 by default)
3. Modify rules of life (begins line 501) by modifying line 504 (rules for death) and line 509 (rules for life). The rules are currently set to default Conway's Game of Life rules (B3, S23). For example, to change to B4, S12, change 2 and 3 in line 504 to 1 and 2 respectively, and 3 in line 509 to 4
4. Specify the desired name and path of the data file to which data is printed in line 391
5. Save the file
6. Drag and drop the file into the SwifthForth console to run

## 2. Test Initial Patterns: conwayslife_test_patterns.f

This file runs Conway's Game of Life on an initial pattern of choice

To use this file:
1. Choose an initial on line 500 with your desired initial pattern. There are 3 options: 1) Glider (make_glider), 2) Blinker (make_blinker), and 3) Still (still_pattern). It is set to "make_glider" by default
2. Set grid size, number of generations, and rules of life as above for the core code (or leave as default)
3. Specify the desired name and path of the data file to which data is printed in line 391
5. Save the file
6. Drag and drop the file into the SwifthForth console to run

## 3. Phase Transitions: conwayslife_phase_transitions.f

This file runs Conway's Game of Life with a phase transition effect. In each generation, each cell is set to have an X% chance of having the rules of Life applied to it, otherwise it is left unchanged. Users can fix X.

To use this file:
1. Set X (probability of rules of Life applying to each cell) by setting the value on line 426 (80 by default)
2. Set grid size, number of generations, and rules of life as above for the core code (or leave as default)
3. Specify the desired name and path of the data file to which data is printed in line 391.
5. Save the file
6. Drag and drop the file into the SwifthForth console to run
