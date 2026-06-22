SHELL := /bin/bash

# ==============================================================================
# 1. VARIABLES
# ==============================================================================
TESTNAME     ?= reg_init_chk
TB_NAME      ?= test_bench
RADIX        ?= decimal
REGRESS_LIST ?= pat.list

# ==============================================================================
# 2. ICARUS VERILOG FLOW 
# ==============================================================================
all_iv: build_iv run_iv
all_wave_iv: build_iv run_iv wave_iv

build_iv:
	@echo "--- [IVERILOG] Compiling test: $(TESTNAME) ---"
	@mkdir -p log
	cp -rf ../tb/$(TESTNAME).v run_test.v
	iverilog -g2012 -o sim.vvp -c compile.f | tee log/compile.log

run_iv:
	@echo "--- [IVERILOG] Executing simulation ---"
	vvp sim.vvp +TESTNAME=$(TESTNAME) | tee log/sim_$(TESTNAME).log
	@mv dump.vcd sim_$(TESTNAME).vcd 2>/dev/null || true

wave_iv:
	@echo "--- [IVERILOG] Opening GTKWave ---"
	gtkwave sim_$(TESTNAME).vcd &

regress_iv:
	@mkdir -p log
	@echo "+--------------------------------+------------------------+----------+"
	@printf "| %-30s | %-22s | %-8s |\n" "PAT_NAME" "RUN_DATE" "RESULT"
	@echo "+--------------------------------+------------------------+----------+"
	@PASSED_CNT=0; TOTAL_CNT=0; FAILED_LIST=""; \
	while IFS= read -r test || [ -n "$$test" ]; do \
		if [[ ! "$$test" =~ ^#.*$$ ]] && [ -n "$$test" ]; then \
			TOTAL_CNT=$$((TOTAL_CNT + 1)); \
			$(MAKE) -s build_iv TESTNAME=$$test > /dev/null 2>&1; \
			$(MAKE) -s run_iv TESTNAME=$$test > /dev/null 2>&1; \
			RUN_DATE=$$(date '+%H:%M:%S %b %d %Y'); \
			if grep -q "PASSED" log/sim_$$test.log; then \
				printf "| %-30s | %-22s | \033[0;32m%-8s\033[0m |\n" "$$test" "$$RUN_DATE" "PASSED"; \
				PASSED_CNT=$$((PASSED_CNT + 1)); \
			else \
				printf "| %-30s | %-22s | \033[0;31m%-8s\033[0m |\n" "$$test" "$$RUN_DATE" "FAILED"; \
				FAILED_LIST="$$FAILED_LIST\n>>> ERROR DETAILS FOR: $$test\n$$(grep -i 'error\|failed' log/sim_$$test.log | sed 's/^/    /')\n"; \
			fi; \
			echo "+--------------------------------+------------------------+----------+"; \
		fi; \
	done < $(REGRESS_LIST); \
	REMAIN=$$((TOTAL_CNT - PASSED_CNT)); \
	echo "TOTAL/PASSED/REMAIN: $$TOTAL_CNT/$$PASSED_CNT/$$REMAIN"; \
	if [ $$REMAIN -ne 0 ]; then \
		echo -e "\n==================== ERROR SUMMARY ===================="; \
		echo -e "$$FAILED_LIST"; \
		echo "======================================================="; \
	fi

# ==============================================================================
# 3. QUESTASIM 
# ==============================================================================
all_qs: build_qs run_qs
all_wave_qs: build_qs run_qs wave_qs

build_qs:
	@echo "--- [QUESTA] Compiling test: $(TESTNAME) ---"
	@mkdir -p log
	cp -rf ../tb/$(TESTNAME).v run_test.v
	vlib work
	vmap work work
	vlog -f compile.f | tee log/compile.log

run_qs:
	@echo "--- [QUESTA] Executing simulation ---"
	vsim -debugDB -l $(TESTNAME).log -voptargs="+acc" -assertdebug -c $(TB_NAME) -do "log -r /*;run -all;"
	cp $(TESTNAME).log ./log
	mv $(TESTNAME).log sim.log

wave_qs:
	@echo "--- [QUESTA] Opening Waveform ---"
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &

# ==============================================================================
# 4. QUESTASIM COVERAGE 
# ==============================================================================
all_cov: build_cov run_cov

build_cov:
	@echo "--- [QUESTA COV] Compiling for coverage: $(TESTNAME) ---"
	@mkdir -p log coverage
	cp -rf ../tb/$(TESTNAME).v run_test.v
	vlib work
	vmap work work
	vlog +cover=bcesft -f compile.f

run_cov:
	@echo "--- [QUESTA COV] Running coverage: $(TESTNAME) ---"
	vsim -debugDB -coverage -l $(TESTNAME).log -c $(TB_NAME) -voptargs="+acc+cover=bcesft" -assertdebug -do "coverage save -onexit $(TESTNAME).ucdb; log -r /*;run -all" +TESTNAME=$(TESTNAME)
	cp $(TESTNAME).log ./log/sim_$(TESTNAME).log
	mv $(TESTNAME).log sim.log

regress_cov:
	@mkdir -p log coverage
	@echo "--- [QUESTA COV] Starting Regression ---"
	@while IFS= read -r test || [ -n "$$test" ]; do \
		if [[ ! "$$test" =~ ^#.*$$ ]] && [ -n "$$test" ]; then \
			echo "Running Test: $$test"; \
			$(MAKE) build_cov TESTNAME=$$test > /dev/null; \
			$(MAKE) run_cov TESTNAME=$$test > /dev/null; \
		fi \
	done < $(REGRESS_LIST)
	$(MAKE) gen_cov
	$(MAKE) gen_html

gen_cov:
	@echo "--- [QUESTA COV] Generating Text Report ---"
	@mkdir -p coverage
	vcover merge IP.ucdb *.ucdb
	vcover report IP.ucdb -output coverage/summary_report.txt
	vcover report -zeros -details -code bcesft -annotate -All -codeAll IP.ucdb -output coverage/detail_report.txt

gen_html:
	@echo "--- [QUESTA COV] Generating HTML Report ---"
	@mkdir -p coverage
	vcover merge IP.ucdb *.ucdb
	vcover report -zeros -details -code bcesft -annotate -testHitDataAll -html IP.ucdb

# ==============================================================================
# 5. UTILITIES
# ==============================================================================
clean:
	@echo "--- [CLEAN] Removing all generated files ---"
	rm -rf log/ work/ coverage/ covhtmlreport/
	rm -rf *.vvp *.log *.vcd *.wlf transcript *.ucdb *.ini vsim.dbg run_test.v
	rm -rf *.cdd tmp*

help:
	@echo ">> ICARUS VERILOG:"
	@echo "   make build_iv     : Build design"
	@echo "   make run_iv       : Run simulation"
	@echo "   make wave_iv      : Open GTKWave"
	@echo "   make regress_iv   : Run all tests in $(REGRESS_LIST) with UI"
	@echo "---------------------------------------------------------------------"
	@echo ">> QUESTASIM:"
	@echo "   make build_qs     : Build design"
	@echo "   make run_qs       : Run simulation"
	@echo "   make wave_qs      : Open Questa Waveform"
	@echo "---------------------------------------------------------------------"
	@echo ">> QUESTASIM COVERAGE:"
	@echo "   make build_cov    : Build design with coverage flags"
	@echo "   make run_cov      : Run simulation and save .ucdb"
	@echo "   make regress_cov  : Run all tests, merge UCDB, generate reports"
	@echo "   make gen_cov      : Generate text reports manually"
	@echo "   make gen_html     : Generate HTML reports manually"
	@echo "---------------------------------------------------------------------"
	@echo ">> COMMON:"
	@echo "   make clean        : Remove all compiled data and logs"
	@echo "====================================================================="