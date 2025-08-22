; *****WANT TO DO STILL*****

; update formulas for existing games
; create new games with formulas
; use games where finding wallets, etc. are used
;     -have them lose items randomly along paths, dorms, etc.
;     -lie controls how they return item
;            -in perfect condition
;            -missing money in wallet
;            -take money and throw away wallet
; make it so non-anon only drops trust once per round per agent
; update P1 to take into account non_anon_play when it is active
; use previous year data to establish evidence for use
; use different college campus maps for spawns in different setup buttons to model schools
; created paths based on department courses for that year to show how they interact

; ***********************************************************************************************************************************************************************
; Alfredo Lorenzo Mendiola
; SP&E 316 Final Project
; 29Dec2022
; Pseudologia Fantastica
; (Pathological Lying)

globals [ ; see ppt for details
  game
  A1
  A2
  B1
  B2
  C1
  C2
  D1
  D2
]

turtles-own [ ; see ppt for details
  trust
  lie
  age
  payoff
  game_count
  lied_to
  partner
  player
  play_actual
  play_tell
]

to setup_p_d ; Prisoner's Dilemma setup
  setup

  ask turtles [
    set game "PD"
    set A1 -6
    set A2 0     ;   --- ----------------- -----------------
    set B1 -10   ;  |   |        C        |        D        |
    set B2 -1    ;   --- ----------------- -----------------
    set C1 -6    ;  | A | (-6[A1],-6[C1]) | (0[A2],-10[D1]) |
    set C2 0     ;   --- ----------------- -----------------
    set D1 -10   ;  | B | (-10[B1],0[C2]) | (-1[B2],-1[D2]) |
    set D2 -1    ;   --- ----------------- -----------------
  ]
end

to setup_g_e ; Gift Exchange setup
  setup

  ask turtles [
    set game "GE"
    set A1 2
    set A2 0     ;   --- --------------- ---------------
    set B1 3     ;  |   |       C       |       D       |
    set B2 1     ;   --- --------------- ---------------
    set C1 2     ;  | A | (2[A1],2[C1]) | (0[A2],3[D1]) |
    set C2 0     ;   --- --------------- ---------------
    set D1 3     ;  | B | (3[B1],0[C2]) | (1[B2],1[D2]) |
    set D2 1     ;   --- --------------- ---------------
  ]
end

to setup
  clear-all
  reset-ticks

  create-turtles initial_pop [
    setxy random-xcor random-ycor
    set trust trust_low + (random (1 + trust_high - trust_low))
    set lie lie_low + (random (1 + lie_high - lie_low))
    set age 0
    set payoff 0
    set game_count 0
    set lied_to 0
    set partner nobody
    set player 0
    set play_actual ""
    set play_tell ""
  ]

  liars

  ask turtles [
    agent_color_shape
  ]
end

to go
  if not any? turtles [ ; ends model if all turtles die
    stop
  ]

  match_up
  play
  move
  tick

  ask turtles [
    set age age + 1
  ]

  new_spawns
  die_spawns
end

to play ; plays the model
  ask turtles with [partner != nobody and player = 0] [ ; assigns P1 and P2
    set player 1
    ask partner [
      set player 2
    ]
  ]

  if game = "PD" [ ; Prisoner's Dilemma
    p_d
  ]
  if game = "GE" [ ; Gift exchange
    g_e
  ]

  ask turtles [
    agent_color_shape
  ]

  reset
end

to p_d ; play for Prisoner's Dilemma setup
  ask turtles with [player = 1] [ ; P1 plays
    if lie >= 80 [ ; always lies plays A
      set play_tell "B"
      set play_actual "A"
    ]
    if lie < 80 and lie > 20 [ ; 50/50 lie or truth to play A/B
      set play_tell "B"
      ifelse (random 100 + 1) mod 2 = 0 [
        set play_actual "A"
      ][
        set play_actual "B"
      ]
    ]
    if lie <= 20 [ ; always truth plays B
      set play_tell "B"
      set play_actual "B"
    ]
    set game_count game_count + 1
  ]

  ask turtles with [player = 2] [ ; P2 play
    if [partner] of partner = self and [play_tell] of partner = "B" [ ; P1 told P2 B
      if trust >= 70 [ ; P2 believes P1 so plays D
        set play_actual "D"
      ]
      if trust < 70 and trust > 30 [ ; 50/50 trusts/distrusts plays C/D
        ifelse (random 100 + 1) mod 2 = 0 [
          set play_actual "D"
        ][
          set play_actual "C"
        ]
      ]
      if trust <= 30 [ ; P2 distrusts P1 so plays C
        set play_actual "C"
      ]
    ]
    set game_count game_count + 1
  ]

  payoffs_pd
end

to payoffs_pd ; checks outcome and distributes payoffs for PD
  ask turtles with [player = 1] [
    if play_tell = "B" and play_actual = "A" [ ; outcomes for lying
      ask partner [ ; increase times lied to for P2
        set lied_to lied_to + 1
      ]
      if non_anon_play? [ ; for non-anonymous play switch
        ask turtles in-radius trust_fall_range [ ; trust falls in a radius of lying P1
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
        ]
      ]
      if [play_actual] of partner = "C" [ ; AC
        set payoff payoff + A1
        set lie lie - (lie_fall_low + (random (1 + lie_fall_high - lie_fall_low)))
        ask partner [
          set payoff payoff + C1
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
        ]

      ]
      if [play_actual] of partner = "D" [ ; AD
        set payoff payoff + A2
        set lie lie + (lie_rise_low + (random (1 + lie_rise_high - lie_rise_low)))
        ask partner [
          set payoff payoff + D1
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
        ]
      ]
    ]
    if play_tell = "B" and play_actual = "B" [ ; outcomes for truth
      if [play_actual] of partner = "C" [ ; BC
        set payoff payoff + B1
        set lie lie + (lie_rise_low + (random (1 + lie_rise_high - lie_rise_low)))
        ask partner [
          set payoff payoff + C2
          set trust trust + (trust_rise_low + (random (1 + trust_rise_high - trust_rise_low)))
        ]
      ]
      if [play_actual] of partner = "D" [ ; BD
        set payoff payoff + B2
        set lie lie - (lie_fall_low + (random (1 + lie_fall_high - lie_fall_low)))
        ask partner [
          set payoff payoff + D2
          set trust trust + (trust_rise_low + (random (1 + trust_rise_high - trust_rise_low)))
        ]
      ]
    ]
  ]

  fix
end

to g_e ; play for Gift Exchange setup
  ask turtles with [player = 1] [ ; P1 plays
    if lie >= 80 [ ; always lies plays B
      set play_tell "A"
      set play_actual "B"
    ]
    if lie < 80 and lie > 20 [ ; 50/50 lie or truth to play A/B
      set play_tell "A"
      ifelse (random 100 + 1) mod 2 = 0 [
        set play_actual "A"
      ][
        set play_actual "B"
      ]
    ]
    if lie <= 20 [ ; always truth plays A
      set play_tell "A"
      set play_actual "A"
    ]
    set game_count game_count + 1
  ]

  ask turtles with [player = 2] [ ; P2 play
    if [partner] of partner = self and [play_tell] of partner = "A" [ ; P1 told P2 B
      if trust >= 70 [ ; P2 believes P1 so plays D to maxi-max
        set play_actual "D"
      ]
      if trust < 70 and trust > 30 [ ; 50/50 trusts/distrusts plays C/D
        ifelse (random 100 + 1) mod 2 = 0 [
          set play_actual "D"
        ][
          set play_actual "C"
        ]
      ]
      if trust <= 30 [ ; P2 distrusts P1 so plays D to maxi-min
        set play_actual "D"
      ]
    ]
    set game_count game_count + 1
  ]

  payoffs_ge
end

to payoffs_ge ; checks outcome and distributes payoffs for GE
  ask turtles with [player = 1] [
    if play_tell = "A" and play_actual = "B" [ ; outcomes for lying
      ask partner [ ; increase times lied to for P2
        set lied_to lied_to + 1
      ]
      if non_anon_play? [ ; for non-anonymous play switch
        ask turtles in-radius trust_fall_range [ ; trust falls in a radius of lying P1
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
        ]
      ]
      if [play_actual] of partner = "C" [ ; BC
        set payoff payoff + B1
        set lie lie + (lie_rise_low + (random (1 + lie_rise_high - lie_rise_low)))
        ask partner [
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
          set payoff payoff + C2
        ]

      ]
      if [play_actual] of partner = "D" [ ; BD
        set lie lie - (lie_fall_low + (random (1 + lie_fall_high - lie_fall_low)))
        set payoff payoff + B2
        ask partner [
          set payoff payoff + D2
          set trust trust - (trust_fall_low + (random (1 + trust_fall_high - trust_fall_low)))
        ]
      ]
    ]
    if play_tell = "A" and play_actual = "A" [ ; outcomes for truth
      if [play_actual] of partner = "C" [ ; AC
        set payoff payoff + A1
        set lie lie - (lie_fall_low + (random (1 + lie_fall_high - lie_fall_low)))
        ask partner [
          set trust trust + (trust_rise_low + (random (1 + trust_rise_high - trust_rise_low)))
          set payoff payoff + C1
        ]
      ]
      if [play_actual] of partner = "D" [ ; AD
        set payoff payoff + A2
        set lie lie + (lie_rise_low + (random (1 + lie_rise_high - lie_rise_low)))
        ask partner [
          set payoff payoff + D1
          set trust trust + (trust_rise_low + (random (1 + trust_rise_high - trust_rise_low)))
        ]
      ]
    ]
  ]

  fix
end

to fix ; keeps changing values within 0 to 100
  ask turtles [
    if trust > 100 [
      set trust 100
    ]
    if trust < 0 [
      set trust 0
    ]
    if lie > 100 [
      set lie 100
    ]
    if lie < 0 [
      set lie 0
    ]
  ]
end

to reset ; resets agents for new round play
  ask turtles [
    set partner nobody
    set player 0
    set play_actual ""
    set play_tell ""
  ]
end

to match_up ; partners up agents within play_range
  ask turtles [
    if any? turtles in-radius play_range [ ; looks for agents in play_range
      if (partner = nobody) and (any? other turtles in-radius play_range with [partner = nobody]) [ ; checks if both agents are unpartnered
        set partner one-of other turtles in-radius play_range with [partner = nobody] ; partners current agent with the other one selected
        ask partner [ ; sets current agent as partner for other agent
          set partner myself
        ]
      ]
    ]
  ]
end

to die_spawns ; checks if it is time to kill agents
  if ticks mod die_ticks = 0 [
    if die_pop > count turtles [
      set die_pop count turtles
    ]
    ask n-of die_pop turtles [ ; kills agents
      die
    ]
  ]
  ask turtles [
    if age >= die_after [
      die
    ]
  ]
end

to new_spawns ; checks if it is time to spawn new agents
  if ticks mod new_ticks = 0 [
    new_spawns_true
  ]
end

to new_spawns_true ; used to spawn new agents normal/liars
  create-turtles (new_pop * ((100 - percent_liars) / 100)) [ ; spawns new non-liars
      setxy random-xcor random-ycor
      set trust trust_low + (random (trust_high - trust_low))
      set lie lie_low + (random (lie_high - lie_low))
      set age 0
      set payoff 0
      set game_count 0
      set lied_to 0
      set partner nobody
      set player 0
      set play_actual ""
      set play_tell ""
      agent_color_shape
  ]

  create-turtles (new_pop * (percent_liars_new / 100)) [ ; spawns new liars
      setxy random-xcor random-ycor
      set trust trust_low + (random (trust_high - trust_low))
      set lie 100
      set age 0
      set payoff 0
      set game_count 0
      set lied_to 0
      set partner nobody
      set player 0
      set play_actual ""
      set play_tell ""
      agent_color_shape
  ]
end

to liars ; creates initial liars
  ask n-of (count turtles * (percent_liars / 100)) turtles [
    set lie 100
  ]
end

to move ; moves agents in range from 0 to move_range
  ask turtles [
    fd random (move_range + 1)
  ]
end

to agent_color_shape ; sets shape/colors/labels for agents
  ifelse lie >= 100 [
    set shape "flag" ; sets shape for liars
  ] [
    set shape "person" ; sets shape for non-liars
  ]

  if trust >= 0 and trust < 20 [ ; low low trust
    set color 15
  ]
  if trust >= 20 and trust < 40 [ ; high low trust
    set color 17
  ]
  if trust >= 40 and trust <= 60 [ ; neutral trust
    set color 9.9
  ]
  if trust > 60 and trust <= 80 [ ; low high trust
    set color 57
  ]
  if trust > 80 and trust <= 100 [ ; high high trust
    set color 55
  ]

  ifelse show_lie? [
    set label lie ; displays lie % over every agent
  ] [
    set label "" ; displays no lie %
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
247
10
709
473
-1
-1
13.76
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
0
466
245
499
Prisoner's Dilemma (-6,-6) (0,-10) (-10,0) (-1,-1)
setup_p_d
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
711
10
798
55
Population
count turtles
17
1
11

MONITOR
711
145
798
190
Average Trust
mean [trust] of turtles
2
1
11

SLIDER
0
256
120
289
move_range
move_range
0
50
5.0
1
1
NIL
HORIZONTAL

BUTTON
584
475
709
508
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
10
244
43
initial_pop
initial_pop
2
1000
500.0
2
1
NIL
HORIZONTAL

SLIDER
0
46
120
79
percent_liars
percent_liars
0
50
7.0
1
1
NIL
HORIZONTAL

SLIDER
0
81
120
114
trust_low
trust_low
0
trust_high
20.0
1
1
NIL
HORIZONTAL

SLIDER
122
81
244
114
trust_high
trust_high
trust_low
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
0
116
120
149
lie_low
lie_low
0
lie_high
7.0
1
1
NIL
HORIZONTAL

SLIDER
122
116
244
149
lie_high
lie_high
lie_low
100
7.0
1
1
NIL
HORIZONTAL

MONITOR
711
280
798
325
Average Lie
mean [lie] of turtles
2
1
11

PLOT
800
208
1062
377
Trust v Lie
Ticks
Average Percentage
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Trust" 1.0 0 -14439633 true "" "plot mean [trust] of turtles"
"Lie" 1.0 0 -5298144 true "" "plot mean [lie] of turtles"

SLIDER
0
151
244
184
new_pop
new_pop
0
1000
50.0
2
1
NIL
HORIZONTAL

SLIDER
0
221
244
254
die_pop
die_pop
0
1000
50.0
2
1
NIL
HORIZONTAL

SLIDER
0
186
120
219
new_ticks
new_ticks
0
250
50.0
1
1
NIL
HORIZONTAL

SLIDER
122
186
244
219
die_ticks
die_ticks
0
250
100.0
1
1
NIL
HORIZONTAL

MONITOR
711
55
798
100
Liars
count turtles with [lie = 100]
2
1
11

PLOT
1064
10
1326
206
Times Lied To
Times Lied To
Amount of Turtles
0.0
1000.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10\nset-plot-x-range 0 (max [lied_to] of turtles)\nset-histogram-num-bars 25"
PENS
"Times lied to" 1.0 1 -16777216 true "" "histogram [lied_to] of turtles"

PLOT
800
379
1062
550
Trust Spread
Trust Percentage
Amount of Turtles
0.0
101.0
0.0
20.0
true
false
"set-histogram-num-bars 10" "set-plot-y-range 0 20"
PENS
"default" 10.0 1 -16777216 true "" "histogram [trust] of turtles"

PLOT
1064
379
1327
549
Lie Spread
Lie Percentage
Amount of Turtles
0.0
101.0
0.0
20.0
true
false
"set-histogram-num-bars 10" "set-plot-y-range 0 20"
PENS
"default" 10.0 1 -16777216 true "" "histogram [lie] of turtles"

MONITOR
711
190
798
235
Lowest Trust
min [trust] of turtles
2
1
11

MONITOR
711
100
798
145
Highest Trust
max [trust] of turtles
2
1
11

MONITOR
711
235
798
280
Highest Lie
max [lie] of turtles
2
1
11

MONITOR
711
325
798
370
Lowest Lie
min [lie] of turtles
2
1
11

PLOT
800
10
1062
206
Games Played
Number of Games Played
Amount of Turtles
0.0
1000.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10\nset-plot-x-range 0 die_after\nset-histogram-num-bars 25"
PENS
"default" 1.0 1 -16777216 true "" "histogram [game_count] of turtles"

MONITOR
711
460
798
505
Lowest Payoff
min [payoff] of turtles
2
1
11

MONITOR
711
370
798
415
Highest Payoff
max [payoff] of turtles
2
1
11

MONITOR
711
415
798
460
Average Payoff
mean [payoff] of turtles
2
1
11

MONITOR
711
505
798
550
Total Payoff
sum [payoff] of turtles
2
1
11

BUTTON
0
501
245
534
Gift Exchange (2,2) (0,3) (3,0) (1,1)
setup_g_e
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
122
256
244
289
play_range
play_range
0
50
3.0
1
1
NIL
HORIZONTAL

SWITCH
584
510
709
543
non_anon_play?
non_anon_play?
1
1
-1000

SLIDER
0
291
120
324
trust_fall_range
trust_fall_range
0
50
3.0
1
1
NIL
HORIZONTAL

PLOT
1064
208
1327
377
Trust t Lie
Average Trust
Average Lie
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"trust t time" 1.0 0 -16777216 true "" "plotxy (mean [trust] of turtles) (mean [lie] of turtles)"

PLOT
1328
10
1591
206
Wealth Spread
Payoff
Amount of Turtles
-10.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 20\nset-plot-x-range (min [payoff] of turtles) (max [payoff] of turtles)\nset-histogram-num-bars 10"
PENS
"Payoff" 1.0 1 -16777216 true "" "histogram [payoff] of turtles"

SLIDER
0
326
120
359
trust_fall_low
trust_fall_low
0
trust_fall_high
1.0
1
1
NIL
HORIZONTAL

SLIDER
122
326
244
359
trust_fall_high
trust_fall_high
trust_fall_low
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
0
396
120
429
lie_fall_low
lie_fall_low
0
lie_fall_high
1.0
1
1
NIL
HORIZONTAL

SLIDER
122
396
244
429
lie_fall_high
lie_fall_high
lie_fall_low
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
0
361
120
394
trust_rise_low
trust_rise_low
0
trust_rise_high
1.0
1
1
NIL
HORIZONTAL

SLIDER
122
361
244
394
trust_rise_high
trust_rise_high
trust_rise_low
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
0
431
120
464
lie_rise_low
lie_rise_low
0
lie_rise_high
1.0
1
1
NIL
HORIZONTAL

SLIDER
122
431
244
464
lie_rise_high
lie_rise_high
lie_rise_low
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
122
291
244
324
die_after
die_after
0
1000
400.0
1
1
NIL
HORIZONTAL

SWITCH
472
510
581
543
show_lie?
show_lie?
1
1
-1000

MONITOR
711
550
798
595
Average Age
mean [age] of turtles
2
1
11

SLIDER
122
46
244
79
percent_liars_new
percent_liars_new
0
50
7.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chess bishop
false
0
Circle -7500403 true true 135 35 30
Circle -16777216 false false 135 35 30
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 165 180 165 195 255
Polygon -16777216 false false 105 255 120 165 180 165 195 255
Rectangle -7500403 true true 105 165 195 150
Rectangle -16777216 false false 105 150 195 165
Line -16777216 false 137 59 162 59
Polygon -7500403 true true 135 60 120 75 120 105 120 120 105 120 105 90 90 105 90 120 90 135 105 150 195 150 210 135 210 120 210 105 195 90 165 60
Polygon -16777216 false false 135 60 120 75 120 120 105 120 105 90 90 105 90 135 105 150 195 150 210 135 210 105 165 60

chess king
false
0
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Polygon -7500403 true true 120 85 105 40 195 40 180 85
Polygon -16777216 false false 119 85 104 40 194 40 179 85
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Rectangle -7500403 true true 165 23 134 13
Rectangle -7500403 true true 144 0 154 44
Polygon -16777216 false false 153 0 144 0 144 13 133 13 133 22 144 22 144 41 154 41 154 22 165 22 165 12 153 12

chess knight
false
0
Line -16777216 false 75 255 225 255
Polygon -7500403 true true 90 255 60 255 60 225 75 180 75 165 60 135 45 90 60 75 60 45 90 30 120 30 135 45 240 60 255 75 255 90 255 105 240 120 225 105 180 120 210 150 225 195 225 210 210 255
Polygon -16777216 false false 210 255 60 255 60 225 75 180 75 165 60 135 45 90 60 75 60 45 90 30 120 30 135 45 240 60 255 75 255 90 255 105 240 120 225 105 180 120 210 150 225 195 225 210
Line -16777216 false 255 90 240 90
Circle -16777216 true false 134 63 24
Line -16777216 false 103 34 108 45
Line -16777216 false 80 41 88 49
Line -16777216 false 61 53 70 58
Line -16777216 false 64 75 79 75
Line -16777216 false 53 100 67 98
Line -16777216 false 63 126 69 123
Line -16777216 false 71 148 77 145
Rectangle -7500403 true true 90 255 210 300
Rectangle -16777216 false false 90 255 210 300

chess queen
false
0
Circle -7500403 true true 140 11 20
Circle -16777216 false false 139 11 20
Circle -7500403 true true 120 22 60
Circle -16777216 false false 119 20 60
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Polygon -7500403 true true 120 75 105 45 195 45 180 75
Polygon -16777216 false false 120 75 105 45 195 45 180 75
Circle -7500403 true true 180 35 20
Circle -16777216 false false 180 35 20
Circle -7500403 true true 140 35 20
Circle -16777216 false false 140 35 20
Circle -7500403 true true 100 35 20
Circle -16777216 false false 99 35 20
Line -16777216 false 105 90 195 90

chess rook
false
0
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 90 255 105 105 195 105 210 255
Polygon -16777216 false false 90 255 105 105 195 105 210 255
Rectangle -7500403 true true 75 90 120 60
Rectangle -7500403 true true 75 84 225 105
Rectangle -7500403 true true 135 90 165 60
Rectangle -7500403 true true 180 90 225 60
Polygon -16777216 false false 90 105 75 105 75 60 120 60 120 84 135 84 135 60 165 60 165 84 179 84 180 60 225 60 225 105

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
