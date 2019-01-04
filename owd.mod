model;

# parameters
param PERIODS;
param GENERATOR_TYPES;
param periods_demand {1..PERIODS};
param periods_length {1..PERIODS};
param available_generators {1..GENERATOR_TYPES};
param load_min {1..GENERATOR_TYPES};
param load_max {1..GENERATOR_TYPES};
param cost_min {1..GENERATOR_TYPES};
param cost_linear {1..GENERATOR_TYPES};
param cost_start {1..GENERATOR_TYPES};

# variables
var active {1..PERIODS, t in 1..GENERATOR_TYPES, 1..available_generators[t]} binary;
var load {1..PERIODS, t in 1..GENERATOR_TYPES, 1..available_generators[t]};

# helper variables
var production {p in 1..PERIODS} = sum {t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i];
var tot_prod = sum {p in 1..PERIODS}  production[p];

# loadmin
subject to st1 {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] >= load_min[t] * active[p,t,i];

# loadmax
subject to st2 {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] <= load_max[t];

# sumT1 <= sumT2 + sumT3
subject to st3 {p in 1..PERIODS}:
  sum {i in 1..available_generators[1]} active[p,1,i] <= sum {i in 1..available_generators[2]} active[p,2,i] + sum {i in 1..available_generators[3]} active[p,3,i];

# satisfy demands
subject to st4 {p in 1..PERIODS}:
  sum {t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i] >= periods_demand[p];

# set active flag
subject to st5 {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]}:
  active[p,t,i] = 0 ==> load[p,t,i] = 0;

# set started flag
var toggled {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} = active[p,t,i] - active[((p+3) mod PERIODS)+1,t,i];
var started {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} = (toggled[p,t,i]^2 + toggled[p,t,i]) / 2;

# calculate total cost
var cost_launch {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} = cost_start[t] * started[p,t,i];
var cost_usage {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} = cost_min[t] + cost_linear[t] * (load[p,t,i] - load_min[t]);
var cost_total = sum {p in 1..PERIODS, t in 1..GENERATOR_TYPES, i in 1..available_generators[t]} (periods_length[p] * cost_usage[p,t,i] + cost_launch[p,t,i]);

# objective function
minimize model: cost_total;