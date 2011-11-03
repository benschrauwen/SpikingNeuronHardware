################################################################################
# Automatically-generated file. Do not edit!
################################################################################

S_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

CC_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

C++_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

CXX_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

CPP_SRCS += \
${addprefix $(ROOT)/, \
}

CC_SRCS += \
${addprefix $(ROOT)/, \
}

C_SRCS += \
${addprefix $(ROOT)/, \
main.c \
}

C_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

CPP_UPPER_SRCS += \
${addprefix $(ROOT)/, \
}

CXX_SRCS += \
${addprefix $(ROOT)/, \
}

S_SRCS += \
${addprefix $(ROOT)/, \
}

C++_SRCS += \
${addprefix $(ROOT)/, \
}

# Each subdirectory must supply rules for building sources it contributes
%.o: $(ROOT)/%.c
	@echo mb-gcc -xl-mode-executable -IC:/temp/NIPSdemo/cpu/microblaze_0/include -O0 -g -c -o$@ $<
	@mb-gcc -xl-mode-executable -IC:/temp/NIPSdemo/cpu/microblaze_0/include -O0 -g -c -o$@ $<
	@echo ' '

%.h: 
	rm -rf $(OBJS) $(DEPS) audiotest.elf
