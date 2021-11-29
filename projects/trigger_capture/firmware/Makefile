BUILD_DIR?=../build/

include $(BUILD_DIR)/software/include/generated/variables.mak
include $(SOC_DIRECTORY)/software/common.mak

vpath %.c $(APP_DIR)/../../board_support/zest_soc/firmware $(APP_DIR)/../../soc/picorv32/firmware/src

OBJECTS   = isr.o helloc.o main.o crt0.o init_zest.o zest.o iserdes.o print.o timer.o
INCLUDES  += -I$(APP_DIR)/../../soc/picorv32/firmware/inc -I$(APP_DIR)/../../board_support/zest_soc/firmware -I$(APP_DIR)/firmware

all: app.bin

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
	chmod -x $@

app.elf: $(OBJECTS)
	$(CC) $(LDFLAGS) \
		-T linker.ld \
		-N -o $@ \
		$(OBJECTS) \
		$(PACKAGES:%=-L$(BUILD_DIR)/software/%) \
		$(LIBS:lib%=-l%)
	chmod -x $@

init_zest.o: init_zest.c
	$(compile)

zest.o: $(APP_DIR)/../../board_support/zest_soc/firmware/zest.c
	$(compile)

main.o: main.c
	$(compile)

crt0.o: $(CPU_DIRECTORY)/crt0.S
	$(assemble)

helloc.o: CFLAGS += -w

%.o: %.c
	$(compile)

%.o: %.S
	$(assemble)

clean:
	$(RM) $(OBJECTS) $(OBJECTS:.o=.d) app.elf app.bin .*~ *~

.PHONY: all main.o clean load
