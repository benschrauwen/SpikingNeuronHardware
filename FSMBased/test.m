[val_syn decay_syn init_syn mw]=get_values(512,0.0005,0.005,10,-1);
[val_membr decay_membr init_membr mw]=get_values(512,0.0005,0.010,10,-1);

add_syn=add_table_satur(val_syn,2);
add_membr=add_table_satur(val_membr,2);

reset_map=calc_secondorder_reset(val_membr, val_syn,0.8);

input = zeros(1, 1000);
input(10:30:500) = 1;
[output membr_state syn_state] = sim_fsm_neuron(input, init_membr, init_syn, decay_membr, decay_syn, add_membr, add_syn, reset_map);

figure(1)
plot(1:length(input),val_membr(membr_state),1:length(input),val_syn(syn_state),1:length(input),val_membr(membr_state)-val_syn(syn_state))
figure(2)
imagesc(reset_map)
