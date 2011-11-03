function gen_mem(m, i, NrPEs, WordWidth, threshold, reset, refr, decay_syn, decay_membr)

%[cft,wt]=conx2conf(m,i);
%[cf,w]=conf2full(cft,wt);
%[conn_in conn_from w] = conf2ind(cft, wt);

% function gen_mem(conn_in, cf, w, NrPEs, WordWidth, threshold, reset, refr, decay_syn, decay_membr)
% 
% m=zeros(length(conn_in),length(conn_in));
% i=zeros(length(conn_in),-min(cf));
% for j=1:length(conn_in)
%     for k=1:length(conn_in{j})
%         ci=conn_in{j}(k);
%         if cf(ci)>0
%             m(j,cf(ci))=w(ci);
%         else
%             i(j,-cf(ci))=w(ci);
%         end
%     end
% end

[cft,wt]=conx2conf(m,i);
[cf,w]=conf2full(cft,wt);

NrNeurons = length(m);
NrCycles = ceil(NrNeurons/NrPEs);

Neuron2PE = mod(0:NrNeurons-1, NrPEs)+1;
Neuron2Cycle =  floor((0:NrNeurons-1)./NrPEs)+1;
PECycle2Neuron = -1*ones(NrPEs, NrCycles);
for i = 1:NrNeurons
    PECycle2Neuron(Neuron2PE(i), Neuron2Cycle(i)) = i;
end

fid=fopen('weight_mem.vhdl', 'w');

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_arith.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_signed.all;' sprintf('\n')];
s =  [s 'use work.settings_package.all;' sprintf('\n')];
s =  [s 'package weight_mem_package is' sprintf('\n')];
s =  [s 'constant weight_mem : weight_mem_type := (\n'];
for n = NrCycles:-1:1
    for i = sum(cf(1,:)~=0,2):-1:1   % all synapses per neuron
        tw = zeros(1, NrPEs, 'uint32');
        for k = NrPEs:-1:1
            if PECycle2Neuron(k, n) > 0
                ww = w(PECycle2Neuron(k, n), i);
                if ww >= 0
                    tw(k) = uint32(ww);
                else
                    tw(k) = bitxor(uint32(-ww),uint32(intmax('int32')))+1;
                end
            else
                tw(k) = uint32(intmax('int32'));
            end
        end
        for j = WordWidth:-1:1
            s = [s '"'];
            for k = NrPEs:-1:1
                if bitand(tw(k), uint32(2^(WordWidth-1))) > 0
                    s = [s '1'];
                else
                    s = [s '0'];
                end
                tw(k) = bitshift(tw(k), 1);
            end
            if j == 1 & i == 1 & n == 1
                s = [s '"'];
            else
                s = [s '",\n'];
            end
        end
        s = [s '\n'];
    end
    s = [s '\n'];
end
s = [s ');\n'];
s = [s 'end weight_mem_package;' sprintf('\n')];
s = [s 'package body weight_mem_package is' sprintf('\n')];
s = [s 'end weight_mem_package;' sprintf('\n')];

fprintf(fid,s);

fclose(fid);

function s = write_val2(s, val, width)
    tw = uint32(val);
    for j = 1:width
        if bitand(tw, uint32(2^(width-1))) > 0
            s = [s '1'];
        else
            s = [s '0'];
        end
        tw = bitshift(tw, 1);
    end
end


fid=fopen('intercon_mem.vhdl', 'w');

AWP = ceil(log2(NrPEs));
AWC = ceil(log2(NrCycles));

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_arith.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_signed.all;' sprintf('\n')];
s =  [s 'use work.settings_package.all;' sprintf('\n')];
s =  [s 'package intercon_mem_package is' sprintf('\n')];
s =  [s 'constant intercon_mem : con_mem_type := (\n'];
for n = NrCycles:-1:1
    for i = sum(cf(1,:)~=0,2):-1:1   % all synapses per neuron
        for k = NrPEs:-1:1
            if PECycle2Neuron(k, n) > 0 & cf(PECycle2Neuron(k, n), i) ~= 0
                s = [s '"'];                
                cff = cf(PECycle2Neuron(k, n), i);
                if cff > 0
                    s = [s '0'];
                    s=write_val2(s,Neuron2Cycle(cff)-1,AWC);
                    s=write_val2(s,Neuron2PE(cff)-1,AWP);
                else
                    s = [s '1'];
                    s=write_val2(s,-cff-1,AWP+AWC);
                end
                if n == 1 & i == 1 & k == 1
                    s = [s '"\n'];                
                else
                    s = [s '",\n'];                
                end
            else
                s = [s '"'];
                for j=1:AWP+AWC+1
                    s = [s '0'];
                end
                s = [s '",\n'];
            end
        end
        s = [s '\n'];                
    end
    s = [s '\n'];                
end
s = [s ');\n'];
s = [s 'end intercon_mem_package;' sprintf('\n')];
s = [s 'package body intercon_mem_package is' sprintf('\n')];
s = [s 'end intercon_mem_package;' sprintf('\n')];

fprintf(fid,s);

fclose(fid);

function s = write_val(s, val,endd)
    ww = val;
    if ww >= 0
        tw = uint32(ww);
    else
        tw = bitxor(uint32(-ww),uint32(intmax('int32')))+1;
    end
    for j = 1:WordWidth
        s = [s '"'];
        for k = 1:NrPEs
            if bitand(tw, uint32(1)) > 0
                s = [s '1'];
            else
                s = [s '0'];
            end
        end
        tw = bitshift(tw, -1);
        if endd & j == WordWidth
            s = [s '"\n'];
        else
            s = [s '",\n'];
        end
    end
    s = [s '\n'];
end


fid=fopen('reg_mem.vhdl', 'w');

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_arith.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_signed.all;' sprintf('\n')];
s =  [s 'use work.settings_package.all;' sprintf('\n')];
s =  [s 'package reg_mem_package is' sprintf('\n')];
s =  [s 'constant reg_mem : reg_mem_type := (\n'];
for n = NrCycles:-1:1
    for i = 1:3*WordWidth     % refr, syn, membr registers
        s = [s '"'];
        for k = 1:NrPEs
            s = [s '0'];
        end
        s = [s '",\n'];
    end
    s = [s '\n'];
    s=write_val(s,threshold,0);
    s=write_val(s,reset,0);
    s=write_val(s,refr,0);
    %s=write_val(s,decay_syn,0);
    %s=write_val(s,decay_membr,n==1);
    s = [s '\n'];
end
s = [s ');\n'];
s = [s 'end reg_mem_package;' sprintf('\n')];
s = [s 'package body reg_mem_package is' sprintf('\n')];
s = [s 'end reg_mem_package;' sprintf('\n')];

fprintf(fid,s);

fclose(fid);


fid=fopen('settings.vhdl', 'w');

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_arith.all;' sprintf('\n')];
s =  [s 'use ieee.std_logic_signed.all;' sprintf('\n')];
s =  [s 'use work.utility_package.all;' sprintf('\n\n')];
s =  [s 'package settings_package is' sprintf('\n')];
s =  [s 'constant CONST_NR_PARALLEL_NEURONS : integer := ' sprintf('%i', NrPEs) ';\n'];
s =  [s 'constant CONST_NR_BITS             : integer := ' sprintf('%i', WordWidth) ';\n'];
s =  [s 'constant CONST_NR_SERIAL_NEURONS   : integer := ' sprintf('%i', NrCycles) ';\n'];
s =  [s 'constant CONST_NR_SYNAPSES         : integer_array  := ('];
for i = 1:NrCycles-1
s = [s '2,'];
end
s = [s '2);\n'];
s =  [s 'constant CONST_NR_WEIGHTS          : integer_matrix := ('];
for i = 1:NrCycles-1
s = [s '(' sprintf('%i', sum(cf(1,:)~=0,2)) ',0),'];
end
s = [s '(' sprintf('%i', sum(cf(1,:)~=0,2)) ',0));\n'];
s = [s 'constant CONST_REFRACTORINESS      : boolean := TRUE;\n'];
s = [s 'constant CONST_REFRACTORY_WIDTH    : integer := ' sprintf('%i', WordWidth) ';\n']; %LOG2CEIL(' sprintf('%i', refr) ');\n'];
s = [s 'constant CONST_DECAY_SHIFT         : integer_matrix := ('];
for i = 1:NrCycles-1
s = [s '(3,4),'];
end
s = [s '(3,4));\n'];
s = [s 'type weight_mem_type is array(0 to TOTAL_NR_WEIGHTS(CONST_NR_WEIGHTS)*CONST_NR_BITS-1) of std_logic_vector(CONST_NR_PARALLEL_NEURONS-1 downto 0);\n'];
s = [s 'type con_mem_type    is array(TOTAL_NR_WEIGHTS(CONST_NR_WEIGHTS)*CONST_NR_PARALLEL_NEURONS-1 downto 0) of std_logic_vector(1+LOG2CEIL(CONST_NR_SERIAL_NEURONS)+LOG2CEIL(CONST_NR_PARALLEL_NEURONS)-1 downto 0);\n'];
s = [s 'type reg_mem_type    is array(0 to TOTAL_MEM(CONST_NR_BITS,CONST_NR_SYNAPSES,CONST_DECAY_SHIFT,CONST_REFRACTORINESS,CONST_REFRACTORY_WIDTH)-1) of std_logic_vector(CONST_NR_PARALLEL_NEURONS-1 downto 0);\n'];
s = [s 'end settings_package;' sprintf('\n')];
s = [s 'package body settings_package is' sprintf('\n')];
s = [s 'end settings_package;' sprintf('\n')];

fprintf(fid,s);

fclose(fid);
end
