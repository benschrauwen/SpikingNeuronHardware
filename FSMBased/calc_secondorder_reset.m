function [reset_map] = calc_secondorder_reset(val_membr, val_syn, reset)

reset_map = zeros(length(val_membr),length(val_syn));

for i = 1:length(val_membr)
    for j = 1:length(val_syn)
        if val_membr(i)-val_syn(j) >= reset
            reset_map(i,j) = 1;
        end    
    end
end
