#!/bin/bash

# get nr of neurons
NEURONS=`grep "NR_NEURONS " settings.vhdl | cut -d = -f 2 | cut -d \; -f 1 | cut -d " " -f 2`
NEURONS=`expr $NEURONS - 1`

#rm -rf xst
#
## synthesize neurons
#for i in `seq 0 $NEURONS`;
#do
#    sed -e 's/--\$NEURON_NR\$/'$i'/g' -e 's/--:=\$NEURON_NR\$/:= '$i'/g' -e 's/--_\$NEURON_NR\$/_'$i'/g' spiking_neuron.vhdl > spiking_neuron_synth.vhdl
#    sed -e 's/\$NEURON_NR\$/'$i'/g' spiking_neuron_synth_templ.xst > spiking_neuron_synth.xst
#    xst -ifn spiking_neuron_synth.xst
#    mv spiking_neuron.ngc spiking_neuron_$i.ngc
#done
#
#rm -rf xst
#
#cp network.vhdl network_temp.vhdl
#for i in `seq 0 $NEURONS`;
#do
#    sed -e 's/-- \$NEURON_DECL\$/component spiking_neuron_'$i' is generic ( NEURON_NR : integer :='$i' ); port( clk :  in std_logic; reset :  in std_logic;  ctr            :  in std_logic_vector(STATE_WIDTH(NEURON_NR)-1 downto 0);    reg_select     :  in std_logic_vector(REG_WIDTH-1 downto 0);    decay          :  in std_logic;    start          :  in std_logic;    write_membr    :  in std_logic;    membr_select   :  in std_logic;    stop_cycle     :  in std_logic;    weight_in : std_logic_vector(WEIGHT_WIDTH-1 downto 0); neuron_outputs :  in std_logic_vector(NR_NEURONS-1 downto 0);    inputs         :  in std_logic_vector(NR_INPUT_NODES-1 downto 0);    output         : out std_logic    ); end component;\n-- \$NEURON_DECL\$/g' -e 's/-- \$NEURON_INST\$/spiking_neuron_instance_'$i': spiking_neuron_'$i' port map(clk, reset, ctr_s, reg_select_s, decay_s, start_s, write_membr_s, membr_select_s, stop_cycle_s, weight_in_s(WEIGHT_WIDTH*('$i'+1)-1 downto WEIGHT_WIDTH*'$i'), s_neuron_outputs, inputs, s_neuron_outputs('$i')); \n-- \$NEURON_INST\$/g' network_temp.vhdl > network_synth.vhdl
#    cp network_synth.vhdl network_temp.vhdl
#done
#sed -e 's/-- \$NEURON_DECL\$//g' -e 's/-- \$NEURON_INST\$//g' network_temp.vhdl > network_synth.vhdl
#rm network_temp.vhdl
#xst -ifn network_synth.xst
#
#rm -rf xst
#
## build ngd
#ngdbuild -p virtex4 -a -u network_synth.ngc

# mapper
map -p 4vsx35-ff668 -k 5 -pr b -cm area -global_opt on -logic_opt on -ol high network_synth.ngd

# place and route
par -w -ub network_synth.ncd network_synth_final

# build bitstream
bitgen -w network_synth_final

# generate post-synth simulation model
netgen -w -ofmt vhdl -sim network_synth.ngd

# generate post-par simulation model
netgen -w -ofmt vhdl -sim network_synth_final.ncd

