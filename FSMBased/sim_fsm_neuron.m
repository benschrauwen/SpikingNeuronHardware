function [output membr_state syn_state] = sim_fsm_neuron(input, init_membr, init_syn, decay_membr, decay_syn, add_membr, add_syn, reset_map)

output = zeros(size(input));
membr_state = zeros(size(input));
syn_state = zeros(size(input));
membr_state(1) = init_membr;
syn_state(1) = init_syn;

for i = 2:length(input)
    % decay
    membr_state(i) = decay_membr(membr_state(i-1));
    syn_state(i) = decay_syn(syn_state(i-1));
    
    % input spikes
    if input(i) == 1
        membr_state(i) = add_membr(membr_state(i-1));
        syn_state(i) = add_syn(syn_state(i-1));
    end
    
    % check reset
    if reset_map(membr_state(i), syn_state(i)) == 1
        membr_state(i) = 1;
        output(i) = 1;
    end
end
