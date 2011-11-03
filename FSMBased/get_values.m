function [values decay_table init min_weight] = get_values(nr_states, dt, tau, thres, reset)

a = exp(-dt/tau);

nr_reset = round((-log(-reset/thres)/(-dt/tau)+nr_states)/2);
nr_thres = nr_states-nr_reset+1;
center = nr_reset+1;

values = zeros(1, nr_states);
values(1) = reset;
values(nr_states)= thres;
values(center) = 0;

for i=2:nr_reset
    values(i) = values(i-1)*a;
end
for i=nr_states-1:-1:nr_reset+2
    values(i) = values(i+1)*a;
end

decay_table = zeros(1, nr_states);
decay_table(center) = center;
decay_table(1:nr_reset) = 2:nr_reset+1;
decay_table(center+1:nr_states) = center:nr_states-1;

init = center;

min_weight = thres*(1-a)/2; % /2 due to round-off