function gen_mem(m, i, NR_SYN, NR_DECAY_STATES, NEURON_TYPE, DECAY)

[cft,wt]=conx2conf(m,i);
[cf,w]=conf2full(cft,wt);

fid=fopen('mem_settings.vhdl', 'w');

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_arith.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_signed.all;' sprintf('\n')];
s =  [s 'use work.neuron_config_package.all;' sprintf('\n')];
s =  [s 'package mem_settings_package is' sprintf('\n')];
fprintf(fid,s);
s =  ['constant MEM : mem_type := (\n'];
for i = 1:NR_SYN
    for j = 1:NR_DECAY_STATES
        for n = 1:length(m)
            nr = sprintf('%i',n-1);
            if NEURON_TYPE == 'li1'
                s =  [s 'conv_std_logic_vector(-' sprintf('%i',DECAY(i)) ', WEIGHT_WIDTH)'];
            elseif NEURON_TYPE == 'li2'
                if j == 1
                    s =  [s 'conv_std_logic_vector(-' sprintf('%i',DECAY(i)) ', WEIGHT_WIDTH)'];
                else
                    s =  [s 'conv_std_logic_vector(' sprintf('%i',DECAY(i)) ', WEIGHT_WIDTH)'];
                end
            elseif NEURON_TYPE == 'sos'
                if j == 1
                    dec_temp = round(exp(-(DECAY(i))/2^8)*256);
                    s =  [s 'conv_std_logic_vector(0, WEIGHT_WIDTH)'];
                else
                    s =  [s 'conv_std_logic_vector(0, WEIGHT_WIDTH)'];
                end
            elseif NEURON_TYPE == 'dos'
                s =  [s 'conv_std_logic_vector(0, WEIGHT_WIDTH)'];
            end
            if n ~= length(m)
                s =  [s ' & '];
            end
        end
        s =  [s ',\n'];
    end
    if i > 1
        for j = 1:sum(cf~=0,2)
            for n = 1:length(m)
                s =  [s 'conv_std_logic_vector(' sprintf('%i',round(w(n,j))) ', WEIGHT_WIDTH)'];
                if n ~= length(m)
                    s =  [s ' & '];
                end
            end
            s =  [s ',\n'];
        end
        for n = 1:length(m)
            s =  [s 'conv_std_logic_vector(0, WEIGHT_WIDTH)'];
            if n ~= length(m)
                s =  [s ' & '];
            end
        end

        if i ~= NR_SYN
            s =  [s ',\n'];
        else
            s =  [s '\n'];
        end
    end
end
s =  [s ');\n\n'];
fprintf(fid,s);

s=  ['end mem_settings_package;' sprintf('\n')];
s = [s 'package body mem_settings_package is' sprintf('\n')];
s=  [s 'end mem_settings_package;' sprintf('\n')];

fprintf(fid,s);

fclose(fid);
