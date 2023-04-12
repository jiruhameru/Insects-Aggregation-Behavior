globals [radius]
patches-own [
  radiusSh_1
  radiusSh_2
  radiusSh_3
  radiusSh_4
]
turtles-own [
  in-the-center ;; default value = 1
  first-simulation ;; default value = 1
  direction
  conspecifics
  conspecifics-rep
  conspecifics-orn

  stopNumber          ;; 0 or 1
  short_stopDurationC ;; Duration of stops in the center
  long_stopDurationC

  short_stopDurationP ;; Duration of stops in the periphery
  long_stopDurationP
  short_stopDurationSh;; Duration of stops under shelter
  long_stopDurationSh
  stopMovInCenter     ;; Probability to stop in the center (S_c)
  stopMovInPeriph     ;; Probability to stop in the periphery (S_p)
  stopUnderShelter    ;; Probability to stop under shelter
  awakeState          ;; Probability to be in awake state (P_s)
  t_short_stop_c      ;; short stop duration in center temporal variable
  t_long_stop_c       ;; long stop duration in center temporal variable
  t_short_stop_p      ;; short stop duration in periphery temporal variable
  t_long_stop_p       ;; long stop duration in periphery temporal variable
  t_short_stopSh      ;; short stop duration under shelter temporal variable (under shelter)
  t_long_stopSh       ;; long stop duration under shelter temporal variable (under shelter)

  neighborsNo
]
to setup
  clear-all
  set radius max-pxcor - 2
  setup-arena
  if allow-shelters = true
   [setup-shelters]
  setup-turtles
  reset-ticks
end

to setup-arena
  let cluster [patches in-radius 15.75] of patch 0 0
  if all? (patch-set [neighbors] of cluster) [pcolor = black] [
  ask cluster [ set pcolor white ]
  ]
end

to setup-turtles
  set-default-shape turtles "roach"
  create-turtles population [
  setxy ((random-float  min-pxcor + random-float  max-pxcor) * 2 / 3)
    ((random-float min-pycor + random-float max-pycor) * 2 / 3)

    set size 1
    set color 35
    set in-the-center 1
    set first-simulation 1

    set stopNumber 0 ;; All is moving
    set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2 ;; S_c
    set stopMovInPeriph precision random-float (1 - probability-to-stop-in-the-periphery) 2;;S_p 80
    set awakeState precision random-float (1 - probability-to-be-in-awake-state) 1

    set short_stopDurationC 0
    set long_stopDurationC 0
    set short_stopDurationP 0
    set long_stopDurationP 0
    set short_stopDurationSh 0
    set long_stopDurationSh 0

  ]
end

to setup-shelters
  ifelse number-of-shelters = 1
  [make-shelter radius-value radius-1 6 6 117]
  [
    ifelse number-of-shelters = 2
    [
     make-shelter radius-value radius-1  6  6 117;;radius-value
     make-shelter radius-value radius-3 -6 -6 65
     ]
    [
      ifelse number-of-shelters = 3
      [
       make-shelter radius-value radius-1  6  6 117
       make-shelter radius-value radius-3 -6 -6 65
       make-shelter radius-value radius-4 -6  6 96
       ]
       [
       make-shelter radius-value radius-1  6  6 117
       make-shelter radius-value radius-3 -6 -6 65
       make-shelter radius-value radius-4 -6  6 96
       make-shelter radius-value radius-2 6  -6 37
        ]
     ]
  ]
end

to make-shelter [shelter_radius xcoor ycoor shel-col]
  let cluster1 [patches in-radius shelter_radius] of patch xcoor ycoor
  ask cluster1 [set pcolor shel-col]

end

to go
  repeat 1 [ask turtles [
    set label-color black
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ifelse abs [pcolor] of patch-ahead 1 = black and in-the-center = 1
      [
        set in-the-center 0
      ]
      [ ifelse in-the-center != 1 and first-simulation = 1
        [ ; set some variables for circular displacements
          set first-simulation 0
          let xx xcor
          let yy ycor
          select-direction heading xcor ycor
          setxy 0 0
          facexy xx yy
          fd 15.0
          ifelse direction = 0
          [rt (-1) * 90]
          [rt 90]
        ] ; ask
        [ ifelse first-simulation = 0
          [
             ifelse ((in-the-center + propability-to-quit-periphery)= 1 and (in-the-center != 1)); return to the center
             [
                set first-simulation 1
                set in-the-center 1
             ]
             [
               ifelse ((stopMovInPeriph + probability-to-stop-in-the-periphery = 1) and (stopMovInPeriph != 1))
               [
                 set stopNumber 1
                 set awakeState precision random-float (1 - probability-to-be-in-awake-state) 1;calculate-probability-to-be-in-awake-state count ([ turtles-on neighbors ] of self);;random probability-to-be-in-awake-state
                 ifelse ((awakeState + probability-to-be-in-awake-state = 1) and (awakeState != 1))
                 [
                   set t_short_stop_p calculate-t-short-stop count ([ turtles-on neighbors ] of self)
                   ifelse (short_stopDurationP >= t_short_stop_p)
                   [
                     set short_stopDurationP 0
                     set stopMovInPeriph precision random-float (1 - probability-to-stop-in-the-periphery) 2
                     set stopNumber 0
                    ]
                   [set short_stopDurationP short_stopDurationP + 1]
                  ]
                 [
                   set t_long_stop_p calculate-t-long-stop count ([ turtles-on neighbors ] of self)
                   ifelse (long_stopDurationP >= t_long_stop_p)
                   [
                     set long_stopDurationP 0
                     set stopMovInPeriph precision random-float (1 - probability-to-stop-in-the-periphery) 2
                     set stopNumber 0
                    ]
                   [set long_stopDurationP long_stopDurationP + 1]
                  ]
                ]
               [
                 set stopNumber 0
                 set stopMovInPeriph precision random-float (1 - probability-to-stop-in-the-periphery) 2;;
                 arc-forward-by-dist direction ; follow  circular movements around the periphery
                 set in-the-center precision random-float (1 - propability-to-quit-periphery) 2;; <-- # Probability to quit the periphery (Q_p)
                ]
             ]
          ]
          [
            ;;;;;;;;;; In the center ;;;;;;;;;;
            spatial-movement
;;;*********************************************************************************************************
            ifelse (pcolor != white); If under a shelter
            [
              ifelse ((stopUnderShelter + prob-stop-under-shelt count ([ turtles-on neighbors ] of self)) = 1 and (stopUnderShelter != 1))
              [
                set stopNumber 1
                set awakeState calculate-probability-to-be-in-awake-state count ([ turtles-on neighbors ] of self)
                ifelse ((awakeState + prob-of-awake-state count ([ turtles-on neighbors ] of self)) = 1 and (awakeState != 1))
                  [
                    set t_short_stopSh calculate-t-short-stopSH count ([ turtles-on neighbors ] of self)
                    ifelse (short_stopDurationSh >= t_short_stopSh)
                      [
                        set short_stopDurationSh 0
                        set stopUnderShelter calculate-probability-to-stop-under-shelter count (([ turtles-on neighbors ] of self)); with [stopNumber = 1])
                        set stopNumber 0
                       ]
                      [set short_stopDurationSh short_stopDurationSh + 1]
                   ]
                  [
                    set t_long_stopSh calculate-t-long-stopSH count ([ turtles-on neighbors ] of self)
                    ifelse (long_stopDurationSh >= t_long_stopSh)
                      [
                        set long_stopDurationSh 0
                        set stopUnderShelter calculate-probability-to-stop-under-shelter count (([ turtles-on neighbors ] of self)); with [stopNumber = 1])
                        set stopNumber 0
                       ]
                      [set long_stopDurationSh long_stopDurationSh + 1]
                   ]
               ]
              [
              ifelse ((stopMovInCenter + probability-to-stop-in-the-center) = 1 and (stopMovInCenter != 1))
              [
                set stopNumber 1
                set awakeState calculate-probability-to-be-in-awake-state count ([ turtles-on neighbors ] of self)
                ifelse ((awakeState + prob-of-awake-state count ([ turtles-on neighbors ] of self)) = 1 and (awakeState != 1))
                [
                  set t_short_stop_c calculate-t-short-stop count ([ turtles-on neighbors ] of self)
                  ifelse (short_stopDurationC >= t_short_stop_c)
                  [
                    set short_stopDurationC 0
                    set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2;; probability in this case is constante regardless of NO of conspecifics.
                    set stopNumber 0
                   ]
                  [set short_stopDurationC short_stopDurationC + 1]
                 ]
                [
                  set t_long_stop_c calculate-t-long-stop count ([ turtles-on neighbors ] of self)
                  ifelse (long_stopDurationC >= t_long_stop_c)
                    [
                      set long_stopDurationC 0
                      set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2;; probability in this case is constante regardless of NO of conspecifics.
                      set stopNumber 0
                     ]
                    [set long_stopDurationC long_stopDurationC + 1]
                 ]
               ]
              [
                ;if (!stopUnderShelter or !stopMovInCenter or !awakeState)
                ;   [
                     set stopNumber 0
                     set stopUnderShelter calculate-probability-to-stop-under-shelter count (([ turtles-on neighbors ] of self)); with [stopNumber = 1])
                     fd 0.1
                     wiggle
                ;    ]
               ]
              ]
             ]
            [;; outside the shelter      *****************************************************
              ifelse ((stopMovInCenter + probability-to-stop-in-the-center) = 1 and (stopMovInCenter != 1))
              [
                set stopNumber 1
                let nbConsp count ([ turtles-on neighbors ] of self)
                set awakeState precision random-float (1 - probability-to-be-in-awake-state) 1;calculate-probability-to-be-in-awake-state nbConsp
                ifelse ((awakeState + probability-to-be-in-awake-state = 1) and (awakeState != 1))
                [
                  set t_short_stop_c calculate-t-short-stop nbConsp
                  ifelse (short_stopDurationC >= t_short_stop_c)
                  [
                    set short_stopDurationC 0
                    set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2;; probability in this case is constante regardless of NO of conspecifics.
                    set stopNumber 0
                   ]
                  [set short_stopDurationC short_stopDurationC + 1]
                 ]
                [
                  set t_long_stop_c calculate-t-long-stop nbConsp
                  ifelse (long_stopDurationC >= t_long_stop_c)
                    [
                      set long_stopDurationC 0
                      set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2;; probability in this case is constante regardless of NO of conspecifics.
                      set stopNumber 0
                     ]
                    [set long_stopDurationC long_stopDurationC + 1]
                 ]
               ]
              [
                set stopNumber 0
                set stopMovInCenter precision random-float (1 - probability-to-stop-in-the-center) 2
                fd 0.1
                wiggle
               ]
             ]
          ]]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ]]]
  tick
end

to find-conspecifics
  set conspecifics other turtles in-cone zone-of-attraction Field-of-perception
  set conspecifics-rep other turtles in-cone zone-of-repulsion Field-of-perception
  set conspecifics-orn other turtles in-cone zone-of-orientation Field-of-perception
end

to spatial-movement
 find-conspecifics
        if any? conspecifics
    [
      ifelse any? conspecifics-rep
      [separate]
      [;align
        if(count conspecifics-orn > 0)
        [cohere]
       ]
    ]

    ;fd 0.1
    ;bounceII
    ;wiggle

end

;----------------------------------------------------------------------------------------------------

to-report radius-value [rad-string]
  ifelse (rad-string = "small")
  [report 2.75]
  [
    ifelse (rad-string = "medium")
    [report 3.75]
    [report 5.75]
   ]
end

to-report average-heading-towards-conspecifics
  let x-component mean [sin (towards myself + 180)] of conspecifics-orn
  let y-component mean [cos (towards myself + 180)] of conspecifics-orn
  ifelse x-component = 0 and y-component = 0
  [report heading]
  [report atan x-component y-component]
end

to-report average-conspecifics-heading
  let x-component sum [dx] of conspecifics
  let y-component sum [dy] of conspecifics
  ifelse x-component = 0 and y-component = 0
  [report heading]
  [report atan x-component y-component]
end

to-report average-heading-towards-conspecifics-rep
  let x-component mean [sin (towards myself + 180)] of conspecifics-rep
  let y-component mean [cos (towards myself + 180)] of conspecifics-rep
  ifelse x-component = 0 and y-component = 0
  [report heading]
  [report atan x-component y-component]
end

to-report calculate-t-short-stop [conspics]
  ifelse (conspics = 0)
  [report short-stop-duration]
  [
    ifelse (conspics = 1)
    [report short-stop-duration-1]
    [
      ifelse (conspics = 2)
      [report short-stop-duration-2]
      [report short-stop-duration-plus]
     ]
   ]
end

to-report calculate-t-long-stop [conspics]; XXXX
  ifelse (conspics = 0)
  [report long-stop-duration]
  [
    ifelse (conspics = 1)
    [report long-stop-duration-1]
    [
      ifelse (conspics = 2)
      [report long-stop-duration-2]
      [report long-stop-duration-plus]
     ]
   ]
end

to-report calculate-t-short-stopSH [conspics]
  ifelse (conspics = 1)
  [report short-stop-duration-1]
  [
    ifelse (conspics = 2)
    [report short-stop-duration-2]
    [report short-stop-duration-plus]
   ]
end

to-report calculate-t-long-stopSH [conspics];XXXX
  ifelse (conspics = 1)
  [report long-stop-duration-1]
  [
    ifelse (conspics = 2)
    [report long-stop-duration-2]
    [report long-stop-duration-plus]
   ]
end

to-report prob-stop-under-shelt [conspics]
  ifelse (conspics = 1)
  [report probability-to-stop-in-the-center-1]
  [
    ifelse (conspics = 2)
    [report probability-to-stop-in-the-center-2]
    [report probability-to-stop-in-the-center-plus]
  ]
end

to-report calculate-probability-to-stop-under-shelter [conspics] ;; probability to stop under shelter in function of NO of conspecifics (S_N) with N= 1, 2, 3+.
  ifelse (conspics = 0)
  [report precision random-float (1 - probability-to-stop-in-the-center) 2]
  [
    ifelse (conspics = 1)
    [report precision random-float (1 - probability-to-stop-in-the-center-1) 2]
    [
    ifelse (conspics = 2)
    [report precision random-float (1 - probability-to-stop-in-the-center-2) 2]
    [report precision random-float (1 - probability-to-stop-in-the-center-plus) 2]
  ]
   ]
end

to-report prob-of-awake-state [conspics]
  ifelse (conspics = 1)
  [report probability-to-be-in-awake-state-1]
  [
    ifelse (conspics = 2)
    [report probability-to-be-in-awake-state-2]
    [report probability-to-be-in-awake-state-plus]
   ]
end

to-report calculate-probability-to-be-in-awake-state [conspics]
  ifelse (conspics = 1)
  [report precision random-float (1 - probability-to-be-in-awake-state) 1]
  [
    ifelse (conspics = 2)
    [report random probability-to-be-in-awake-state-2]
    [report random probability-to-be-in-awake-state-plus]
  ]
end

to turn-away [new-heading max-turn]
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]
  ifelse abs turn > max-turn
  [ifelse turn > 0
    [ rt max-turn ]
    [ lt max-turn ]
  ]
  [rt turn]
end

to turn-towards [new-heading max-turn]
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to separate
  turn-away average-heading-towards-conspecifics-rep max-turning-rate
end

to align
  turn-towards average-conspecifics-heading max-turning-rate
end

to cohere
  turn-towards average-heading-towards-conspecifics max-turning-rate
end


;----------------------------------------------------------------------------------------------------

to arc-forward-by-dist [direct] ;; turtle procedure
  ;; calculate how much of an angle we'll be turning through
  ;; (essentially converting radians to degrees)
  ;let theta 180 / (pi * 15.0)
  let theta 180 / (pi * 75.0);
  ;; turn to face the next point we're going to

  ifelse direct = 0
    [
      rt (-1) * theta / 2
      ;; go there
      fd 0.2
      ;; turn to face tangent to the circle
      rt (-1) * theta / 2
    ]
    [
      rt theta / 2
      ;; go there
      fd 0.2
      ;; turn to face tangent to the circle
      rt theta / 2
    ]
end

to select-direction [ turtle-heading turtle-x-coord turtle-y-coord ]
  if (turtle-heading <= 90) and (xcor >= 0) and (ycor > max-pycor / 2)
  [set direction 1]
  if (turtle-heading <= 90) and (xcor > max-pxcor / 2) and (ycor >= 0)
  [set direction 0]
  ;-------------------
  if (turtle-heading <= 90) and (xcor <= 0) and (ycor >= 0)
  [set direction 1]
  ;-------------------
  if (turtle-heading <= 90) and (xcor > 0) and (ycor <= 0)
  [set direction 0]
  ;;====================================================================
  if (turtle-heading > 90) and (xcor >= max-pxcor / 2) and (ycor >= 0)
  [set direction 1]
  ;-------------------
  if (turtle-heading > 90) and (xcor >= 0) and (ycor <= max-pycor / 2)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 90) and (xcor <= 0) and (ycor <= 0)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 90) and (xcor >= 0) and (ycor >= 0)
  [set direction 1]
  ;;====================================================================
  if (turtle-heading > 180) and (xcor <= 0) and (ycor <= max-pycor / 2)
  [set direction 1]
  ;-------------------
  if (turtle-heading > 180) and (xcor <= max-pxcor / 2) and (ycor <= 0)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 180) and (xcor <= 0) and (ycor >= 0)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 180) and (xcor >= 0) and (ycor <= 0)
  [set direction 1]
  ;;====================================================================
  if (turtle-heading > 225) and (xcor <= max-pxcor / 2) and (ycor >= 0)
  [set direction 1]
  ;-------------------
  if (turtle-heading > 225) and (xcor <= 0) and (ycor >= max-pxcor / 2)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 225) and (xcor >= 0) and (ycor >= 0)
  [set direction 0]
  ;-------------------
  if (turtle-heading > 225) and (xcor <= 0) and (ycor <= 0)
  [set direction 1]

end

to bounce
    ; check: hitting 0 0
  if ([pxcor] of patch-ahead 1 >= 0) and ([pycor] of patch-ahead 1 > 0)
    [ set heading (heading + 180) ]
    ; check: hitting 0 1
  if ([pxcor] of patch-ahead 1 > 0) and ([pycor] of patch-ahead 1 < 0)
    [ set heading (360 - (heading - 90)) ]
    ; check: hitting 1 0
  if ([pxcor] of patch-ahead 1 < 0) and ([pycor] of patch-ahead 1 < 0)
      [ set heading (heading - 180) ]
    ; check: hitting 1 1
  if ([pxcor] of patch-ahead 1 < 0) and ([pycor] of patch-ahead 1 > 0)
      [ set heading ((360 - heading) + 90) ]
end

to bounceII  ;; balls procedure
  ;; bounce off left and right walls
  ifelse (abs pxcor = max-pxcor) or abs pycor = max-pycor
  [if  (abs pxcor = max-pxcor)
    [ set heading (- heading)
      ]
  ;; bounce off top and bottom walls
  if abs pycor = max-pycor
    [ set heading (180 - heading)
      ]]
    [if [pcolor] of patch-at dx 0 = black [
    set heading (- heading)
  ]
  if [pcolor] of patch-at 0 dy = black [
    set heading (180 - heading)
  ]]
end


to wiggle  ;; turtle procedure
  rt random 35
  lt random 35
  if abs [pxcor] of patch-ahead 0.1 = max-pxcor
  [ set heading (- heading) ]
  if abs [pycor] of patch-ahead 0.1 = max-pycor
  [ set heading (180 - heading) ]
  ;if not can-move? 5 [ rt 180 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
844
15
1257
429
-1
-1
12.3
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
1
1
1
ticks
30.0

BUTTON
17
23
80
56
NIL
setup
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
94
21
290
54
population
population
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
16
65
79
98
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
8
111
278
144
Field-of-perception
Field-of-perception
200
360
347.0
1
1
NIL
HORIZONTAL

SLIDER
12
195
278
228
zone-of-repulsion
zone-of-repulsion
0.0
5.0
0.0
0.25
1
NIL
HORIZONTAL

SLIDER
12
236
277
269
zone-of-orientation
zone-of-orientation
0.0
10.0
0.0
0.5
1
NIL
HORIZONTAL

SLIDER
10
284
278
317
max-turning-rate
max-turning-rate
10
100
17.0
1
1
NIL
HORIZONTAL

SLIDER
11
155
279
188
zone-of-attraction
zone-of-attraction
0.0
10.0
10.0
0.5
1
NIL
HORIZONTAL

SWITCH
1
363
138
396
allow-shelters
allow-shelters
0
1
-1000

TEXTBOX
9
340
179
368
ــــــــEnvironment parametersــــــــ
11
0.0
1

TEXTBOX
314
10
736
28
ـــــــــــــــــــــــــــــــــــــSimulation parametersـــــــــــــــــــــــــــــــــــــ
11
0.0
1

SLIDER
298
40
516
73
probability-to-stop-in-the-center
probability-to-stop-in-the-center
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
299
74
516
107
probability-to-stop-in-the-periphery
probability-to-stop-in-the-periphery
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
298
109
516
142
probability-to-be-in-awake-state
probability-to-be-in-awake-state
0
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
303
215
457
248
short-stop-duration
short-stop-duration
0
50
12.0
1
1
ticks
HORIZONTAL

SLIDER
303
250
458
283
long-stop-duration
long-stop-duration
0
100
69.0
1
1
ticks
HORIZONTAL

TEXTBOX
304
25
512
44
(number of conspecifics = 0) (Basic model)
11
74.0
1

SLIDER
529
42
802
75
probability-to-stop-in-the-center-1
probability-to-stop-in-the-center-1
0
1
0.92
0.01
1
NIL
HORIZONTAL

SLIDER
530
76
802
109
probability-to-stop-in-the-center-2
probability-to-stop-in-the-center-2
0
1
0.89
0.01
1
NIL
HORIZONTAL

SLIDER
530
111
802
144
probability-to-stop-in-the-center-plus
probability-to-stop-in-the-center-plus
0
1
0.83
0.01
1
NIL
HORIZONTAL

TEXTBOX
519
25
534
238
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n
11
74.0
1

SLIDER
529
149
801
182
probability-to-be-in-awake-state-1
probability-to-be-in-awake-state-1
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
530
186
801
219
probability-to-be-in-awake-state-2
probability-to-be-in-awake-state-2
0
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
530
220
801
253
probability-to-be-in-awake-state-plus
probability-to-be-in-awake-state-plus
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
468
258
649
291
short-stop-duration-1
short-stop-duration-1
0
50
2.0
1
1
ticks
HORIZONTAL

SLIDER
468
292
649
325
short-stop-duration-2
short-stop-duration-2
0
50
4.0
1
1
ticks
HORIZONTAL

SLIDER
468
327
649
360
short-stop-duration-plus
short-stop-duration-plus
0
50
6.0
1
1
ticks
HORIZONTAL

SLIDER
655
257
827
290
long-stop-duration-1
long-stop-duration-1
0
2000
688.0
1
1
NIL
HORIZONTAL

SLIDER
656
291
827
324
long-stop-duration-2
long-stop-duration-2
0
2000
1269.0
1
1
ticks
HORIZONTAL

SLIDER
655
326
828
359
long-stop-duration-plus
long-stop-duration-plus
0
2000
1519.0
1
1
ticks
HORIZONTAL

TEXTBOX
529
24
779
52
(number of conspecifics (n) > 0) (extended model)
11
74.0
1

SLIDER
299
163
514
196
propability-to-quit-periphery
propability-to-quit-periphery
0
1
0.75
0.01
1
NIL
HORIZONTAL

CHOOSER
0
403
138
448
number-of-shelters
number-of-shelters
1 2 3 4
3

PLOT
583
367
840
517
proportion of moving roaches
time
populaiton
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"arena" 1.0 0 -16777216 true "" "plot count turtles with [pcolor = white and stopNumber = 0]"
"shelter-1" 1.0 0 -5204280 true "" "plot count turtles with [pcolor = 117 and stopNumber = 0]"
"shelter-2" 1.0 0 -3889007 true "" "plot count turtles with [pcolor = 37 and stopNumber = 0]"
"shelter-3" 1.0 0 -13840069 true "" "plot count turtles with [pcolor = 65 and stopNumber = 0]"
"shelter-4" 1.0 0 -11033397 true "" "plot count turtles with [pcolor = 96 and stopNumber = 0]"

PLOT
346
363
576
517
Proportion of stopping roaches
time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"arena" 1.0 0 -16777216 true "" "ifelse ((count turtles with [pcolor = white and stopNumber = 1]) = 0)\n[plot count turtles with [pcolor = white and stopNumber = 1]]\n[plot count turtles with [pcolor = white and stopNumber = 1]]"
"shelter-1" 1.0 0 -5204280 true "" "ifelse ((count turtles with [pcolor = 117 and stopNumber = 1]) = 0)\n[plot count turtles with [pcolor = 117 and stopNumber = 1]]\n[plot count turtles with [pcolor = 117 and stopNumber = 1]]"
"shelter-2" 1.0 0 -3889007 true "" "ifelse ((count turtles with [pcolor = 37 and stopNumber = 1]) = 0)\n[plot count turtles with [pcolor = 37 and stopNumber = 1]]\n[plot count turtles with [pcolor = 37 and stopNumber = 1]]"
"shelter-3" 1.0 0 -13840069 true "" "ifelse ((count turtles with [pcolor = 65 and stopNumber = 1]) = 0)\n[plot count turtles with [pcolor = 65 and stopNumber = 1]]\n[plot count turtles with [pcolor = 65 and stopNumber = 1]]"
"shelter-4" 1.0 0 -11033397 true "" "ifelse ((count turtles with [pcolor = 96 and stopNumber = 1] = 0))\n[plot count turtles with [pcolor = 96 and stopNumber = 1]]\n[plot count turtles with [pcolor = 96 and stopNumber = 1]]"

CHOOSER
148
382
240
427
radius-1
radius-1
"small" "medium" "large"
0

CHOOSER
147
428
241
473
radius-2
radius-2
"small" "medium" "large"
1

CHOOSER
248
383
341
428
radius-3
radius-3
"small" "medium" "large"
1

CHOOSER
248
430
341
475
radius-4
radius-4
"small" "medium" "large"
2

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

roach
true
14
Circle -6459832 true false 118 43 62
Polygon -6459832 true false 165 90 180 105 195 135 195 165 195 210 180 240 165 255 150 255 135 255 120 240 120 225 120 240 105 225 105 195 105 165 105 135 105 120 120 120 120 105 135 90
Polygon -6459832 false false 120 105 105 120 135 135
Polygon -6459832 true false 150 135 120 105 105 120 135 135
Polygon -6459832 false false 165 60 165 45 180 30 195 30 225 30 180 30 150 60 135 45 105 30 90 30 75 45 90 30 105 30 135 45
Polygon -7500403 false false 180 120 210 105 180 120
Polygon -6459832 false false 180 120 210 105 165 135
Polygon -6459832 false false 120 120 90 105 105 120
Line -6459832 false 135 165 75 150
Line -6459832 false 180 165 225 150
Line -6459832 false 195 195 195 180
Line -6459832 false 195 240 210 210
Line -6459832 false 105 195 90 210
Line -6459832 false 90 210 105 240
Line -6459832 false 195 195 210 210

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
NetLogo 6.0.4
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
