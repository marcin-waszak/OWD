model;

# parameters
set GENERATOR_TYPES ordered;
param PERIODS;
param periods_demand {1..PERIODS};
param periods_length {1..PERIODS};
param available_generators {GENERATOR_TYPES};
param load_min {GENERATOR_TYPES};
param load_max {GENERATOR_TYPES};
param cost_min {GENERATOR_TYPES};
param cost_linear {GENERATOR_TYPES};
param cost_start {GENERATOR_TYPES};

# variables
var active {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]} binary;
var load {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]};

# helper parameters and variables
param demand_total = sum {p in 1..PERIODS} periods_demand[p];
var production {p in 1..PERIODS} = sum {t in GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i];
var production_total = sum {p in 1..PERIODS} production[p];
var demand_increase = production_total / demand_total;

# loadmin
subject to st1 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] >= load_min[t] * active[p,t,i];

# loadmax
subject to st2 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  load[p,t,i] <= load_max[t];

# sumT1 <= sumT2 + sumT3
var sum_generators {p in 1..PERIODS, t in GENERATOR_TYPES} = sum {i in 1..available_generators[t]} active[p,t,i];
subject to st3 {p in 1..PERIODS}:
  sum_generators[p,"T1"] <= sum_generators[p,"T2"] + sum_generators[p,"T3"];

# satisfy power demands
subject to st4 {p in 1..PERIODS}:
  sum {t in GENERATOR_TYPES, i in 1..available_generators[t]} load[p,t,i] >= periods_demand[p];

# set active flag
subject to st5 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  active[p,t,i] = 0 ==> load[p,t,i] = 0;

# set started flag
var toggled {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = active[p,t,i] - active[((p+3) mod PERIODS)+1,t,i];
var started {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = (toggled[p,t,i]^2 + toggled[p,t,i]) / 2;

# calculate total cost
var cost_launch {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = cost_start[t] * started[p,t,i];
var cost_usage {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = cost_min[t] + cost_linear[t] * (load[p,t,i] - load_min[t]);
var cost_total = sum {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} (periods_length[p] * cost_usage[p,t,i] + cost_launch[p,t,i]);

# objective function for minimal cost
minimize minimize_cost: cost_total;

# weighted objectives Method
param weight;
maximize weighted_objectives: weight*demand_increase - cost_total;