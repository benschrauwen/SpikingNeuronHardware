#!/bin/bash

# get nr of neurons
NEURONS=`grep "NR_NEURONS " settings.vhdl | cut -d = -f 2 | cut -d \; -f 1 | cut -d " " -f 2`
NEURONS=`expr $NEURONS - 1`

# synthesize dendrite adder
xst -ifn dendrite_adder.xst

# synthesize membrane
xst -ifn membrane.xst

rm -rf xst

# synthesize neurons
for i in `seq 129 $NEURONS`;
do
    sed -e 's/\$NEURON_NR\$/'$i'/g' neuron_templ.vhdl > neuron.vhdl
    sed -e 's/\$NEURON_NR\$/'$i'/g' neuron_templ.xst > neuron.xst
    xst -ifn neuron.xst
    mv neuron.ngc neuron_$i.ngc
done

rm -rf xst

# synthesize network
cp network_templ.vhdl network_temp.vhdl
for i in `seq 0 $NEURONS`;
do
    sed -e 's/\$TEMPL\$/neur'$i': neuron_'$i' port map(clk, s_reset_out, s_neuron_outputs, inputs, s_integrate, s_decay, s_state_end, s_tap, s_extend, s_neuron_outputs('$i'));\n\$TEMPL\$/g' -e 's/\$DECL_TEMPL\$/component neuron_'$i' is generic (NEURON_NR : integer := '$i'); port (clk         :  in std_logic; reset       :  in std_logic; neuron_outputs      :  in std_logic_vector(NR_NEURONS-1 downto 0);   inputs              :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);                                           integrate   :  in std_logic;                                decay       :  in std_logic;                                    state_end   :  in std_logic;                                        tap         :  in std_logic_vector(NR_TAPS_BITS-1 downto 0);                                            extend      :  in std_logic_vector(NR_SYN_MODELS downto 0);                                                                                            output      : out std_logic                                                );                                                end component;\n\$DECL_TEMPL\$/g' network_temp.vhdl > network.vhdl
    mv network.vhdl network_temp.vhdl
done
sed -e 's/\$TEMPL\$//g' -e 's/\$DECL_TEMPL\$//g' network_temp.vhdl > network.vhdl
rm network_temp.vhdl
xst -ifn network_hardware.xst

# build ngd
ngdbuild -p virtex4 -a -u network_hardware.ngc

# mapper
map -p 4vsx35-ff668 -k 5 -pr b -cm area network_hardware.ngd

# place and route 
par -w -ub network_hardware.ncd network_hardware_final

# build bitstream
bitgen -w network_hardware_final

# generate post-synth simulation model
netgen -w -ofmt vhdl -sim network_hardware.ngd 

# generate post-par simulation model
netgen -w -ofmt vhdl -sim network_hardware_final.ncd
