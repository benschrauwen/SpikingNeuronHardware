function create_settings (m, i)

n=length(m);
n_inputs = size(i,2);

[cft,wt]=conx2conf(m,i);
[cf,w]=conf2full(cft,wt);

s =  ['library ieee;' sprintf('\n')];
s =  [s 'use ieee.std_logic_1164.all;' sprintf('\n')];
s =  [s 'use work.utility_package.all;' sprintf('\n')];
s =  [s 'package settings_package is' sprintf('\n')];
s =  [s 'constant NR_NEURONS         : integer := ' sprintf('%i;\n',n)];
s =  [s 'constant NR_INPUT_NODES     : integer := ' sprintf('%i;\n',n_inputs)];
s =  [s 'constant CONN_FROM          : integer_matrix := ' mat2vhdl(cf)];
s =  [s 'constant NR_OUTPUT_NODES    : integer := ' sprintf('%i;\n',n)];
s =  [s 'constant OUTPUT_NODES       : integer_array := ' vect2vhdl(1:n)];
s =  [s 'constant WEIGHTS            : integer_matrix := ' mat2vhdl(w)];
s =  [s 'constant SYNAPSE_MAP        : integer_matrix := ' mat2vhdl(sum(cf~=0,2))];
s=  [s 'end settings_package;' sprintf('\n')];
s = [s 'package body settings_package is' sprintf('\n')];
s=  [s 'end settings_package;' sprintf('\n')];

fid=fopen('settings.vhdl', 'w');
fprintf(fid,s);
fclose(fid);
