################################################################################
# Automatically-generated file. Do not edit!
################################################################################

ROOT := ..

-include $(ROOT)/makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include $(SUBDIRS:%=%/subdir.mk)
-include objects.mk
-include $(DEPS)
-include $(ROOT)/makefile.defs

all: audiotest.elf

audiotest.elf: $(HDRS) $(OBJS)
	@echo 'Building target: $@'
	mb-gcc -o $@ $(OBJS) $(USER_OBJS) $(LIBS) -LC:/temp/NIPSdemo/cpu/microblaze_0/lib
	@echo 'Finished building: $@'

	mb-size $@

clean:
	-$(RM) $(OBJS) $(DEPS) audiotest.elf

.PHONY: all clean dependents

-include $(ROOT)/makefile.targets
