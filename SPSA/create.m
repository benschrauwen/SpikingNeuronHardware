addpath ../../../RCToolbox/topology/
addpath ../../../RCToolbox/reservoir/ESSpiNN/
addpath ../../../Models/NetworkCreation

m = gen_rand_k(500,10);
m = assign_rand(m,[1 20]);
ind = find(m>0);
r = randperm(500*10);
m(ind(r(1:500))) = -m(ind(r(1:500)));
m = round(m);

i = [zeros([500 5]), gen_rand_k([500 78],2), zeros([500 5])];
i = assign_rand(i,[1 50]);
i = round(i);

gen_mem(m, i, 100, 11, 300, -20, 2, 0, 0)