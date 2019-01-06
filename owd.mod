model;

# parameters
set GENERATOR_TYPES ordered;
param PERIODS;
param period_demand {1..PERIODS};
param period_length {1..PERIODS};
param available_generators {GENERATOR_TYPES};
param power_min {GENERATOR_TYPES};
param power_max {GENERATOR_TYPES};
param cost_min {GENERATOR_TYPES};
param cost_linear {GENERATOR_TYPES};
param cost_start {GENERATOR_TYPES};

# variables
var active {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]} binary;
var power {1..PERIODS, t in GENERATOR_TYPES, 1..available_generators[t]};

# helper parameters and variables
param demand_total = sum {p in 1..PERIODS} period_demand[p] * period_length[p];
var period_power {p in 1..PERIODS} = sum {t in GENERATOR_TYPES, i in 1..available_generators[t]} power[p,t,i];
var production_total = sum {p in 1..PERIODS} period_power[p] * period_length[p];
var demand_increase = production_total / demand_total;

# powermin
subject to st1 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  power[p,t,i] >= power_min[t] * active[p,t,i];

# powermax
subject to st2 {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]}:
  power[p,t,i] <= power_max[t] * active[p,t,i];

# sumT1 <= sumT2 + sumT3
var sum_generators {p in 1..PERIODS, t in GENERATOR_TYPES} = sum {i in 1..available_generators[t]} active[p,t,i];
subject to st3 {p in 1..PERIODS}:
  sum_generators[p,"T1"] <= sum_generators[p,"T2"] + sum_generators[p,"T3"];

# satisfy power demands
subject to st4 {p in 1..PERIODS}:
  period_power[p] >= period_demand[p];

# set started flag
var toggled {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = active[p,t,i] - active[((p+3) mod PERIODS)+1,t,i];
var started {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = (toggled[p,t,i]^2 + toggled[p,t,i]) / 2;

# calculate total cost
var cost_launch {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = cost_start[t] * started[p,t,i];
var cost_usage {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} = cost_min[t] + cost_linear[t] * (power[p,t,i] - power_min[t]);
var cost_total = sum {p in 1..PERIODS, t in GENERATOR_TYPES, i in 1..available_generators[t]} (period_length[p] * cost_usage[p,t,i] + cost_launch[p,t,i]);

# objective function for minimal cost
minimize minimize_cost: cost_total;

# objective function for weighted objectives method
param weight;
maximize weighted_objectives: weight*demand_increase - cost_total;

# objective function for interval reference point method
param epsilon;
param gamma;
param beta;
param a1;
param r1;
param a2;
param r2;

var v;
var z1;
var z2;

subject to irpm1: v <= z1;
subject to irpm2: v <= z2;
subject to irpm3: z1 <= gamma * (cost_total - r1) / (a1 - r1);
subject to irpm4: z1 <= (cost_total - r1) / (a1 - r1);
subject to irpm5: z1 <= beta * (cost_total - a1) / (a1 - r1) + 1;
subject to irpm6: z2 <= gamma * (demand_increase - r2) / (a2 - r2);
subject to irpm7: z2 <= (demand_increase - r2) / (a2 - r2);
subject to irpm8: z2 <= beta * (demand_increase - a2) / (a2 - r2) + 1;

maximize interval_rpm: v + epsilon * (z1 + z2);
