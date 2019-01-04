model;

# parameters
param PERIODS;
param periods_demand {1..PERIODS};
param periods_length {1..PERIODS};
set GENERATOR_TYPES ordered;
param available_generators {GENERATOR_TYPES};
param load_min {GENERATOR_TYPES};
param load_max {GENERATOR_TYPES};
param cost_min {GENERATOR_TYPES};
param cost_linear {GENERATOR_TYPES};
param cost_start {GENERATOR_TYPES};

# variables
var active {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]} binary;
var load {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]};

# helper variables
var production {p in 1..PERIODS} = sum {t in GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i];
var tot_prod = sum {p in 1..PERIODS}  production[p];

# loadmin
subject to st1 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] >= load_min[t] * active[p,t,i];

# loadmax
subject to st2 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] <= load_max[t];

# sumT1 <= sumT2 + sumT3
subject to st3 {p in 1..PERIODS}:
  sum {i in 1..available_generators[member(1,GENERATOR_TYPES)]} active[p,member(1,GENERATOR_TYPES),i] <= sum {i in 1..available_generators[member(2,GENERATOR_TYPES)]} active[p,member(2,GENERATOR_TYPES),i] + sum {i in 1..available_generators[member(3,GENERATOR_TYPES)]} active[p,member(3,GENERATOR_TYPES),i];

# satisfy demands
subject to st4 {p in 1..PERIODS}:
  sum {t in GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i] >= periods_demand[p];

# set active flag
subject to st5 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  active[p,t,i] = 0 ==> load[p,t,i] = 0;

  
var cost = sum {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} periods_length[p] * (cost_min[t] + cost_linear[t] * (load[p,t,i] - load_min[t]));

minimize model: cost;