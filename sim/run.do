# ==============================================================================
# QUESTA DUAL-TESTBENCH SCRIPT (VERILOG vs SYSTEMVERILOG)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. HÀM DỌN DẸP (CLEAN)
# ------------------------------------------------------------------------------
proc clean {} {
    echo "\n--- \[CLEAN\] Dang don dep file rac ---"
    quit -sim
    if {[file exists work]} { vdel -lib work -all }
    file delete -force log coverage covhtmlreport
    foreach f [glob -nocomplain *.vvp *.log *.vcd *.wlf transcript *.ucdb *.ini vsim.dbg run_test.v *.cdd tmp*] {
        file delete -force $f
    }
    echo "--- Don dep hoan tat! ---\n"
}

# ------------------------------------------------------------------------------
# 2. LUỒNG CHẠY VERILOG TESTBENCH (Thư mục tb_v)
# ------------------------------------------------------------------------------
proc run_v {testname} {
    echo "\n--- \[VERILOG FLOW\] Dang bien dich RTL va Testbench cu... ---"
    quit -sim
    if {![file exists work]} { vlib work; vmap work work }

    # Bien dich RTL
    vlog ../rtl/*.v
    
    # COPY FILE TESTCASE THANH run_test.v (Giong Makefile)
    file copy -force ../tb_v/${testname}.v run_test.v
    
    # BIEN DICH FILE TEST_BENCH TONG
    vlog -sv ../tb_v/testbench.v
    
    echo "--- \[VERILOG FLOW\] Bat dau mo phong testcase: $testname ---"
    vsim -voptargs="+acc" -onfinish stop work.test_bench +TESTNAME=$testname
    
    add wave -position insertpoint sim:/test_bench/dut/*
    radix -hexadecimal
    run -all
}

# ------------------------------------------------------------------------------
# 2.5. LUỒNG CHẠY HÀNG LOẠT VERILOG TESTBENCH (REGRESSION)
# ------------------------------------------------------------------------------
proc regress_v {} {
    echo "\n====================================================================="
    echo "                 BAT DAU CHAY REGRESSION (VERILOG)                   "
    echo "====================================================================="

    # Kiem tra xem file pat.list co ton tai khong
    if {![file exists pat.list]} {
        echo "Loi: Khong tim thay file pat.list trong thu muc hien tai!"
        return
    }

    file mkdir log
    quit -sim
    if {![file exists work]} { vlib work; vmap work work }
    vlog -quiet ../rtl/*.v

    set total_cnt 0
    set passed_cnt 0
    set failed_list ""
    
    # Tao bien de gom cac dong cua Bang Thong Ke lai
    set summary_table ""

    set fp [open pat.list r]
    set lines [split [string map {\r ""} [read $fp]] "\n"]
    close $fp

    foreach test $lines {
        set test [string trim $test]
        if {$test == "" || [regexp {^#} $test]} { continue }

        incr total_cnt
        
        # In ra mot dong de biet dang chay test nao
        echo "\n---> Dang chay mo phong: $test ..."

        file copy -force ../tb_v/${test}.v run_test.v
        vlog -sv -quiet ../tb_v/testbench.v
        
        # Dung lenh vsim binh thuong, khong dung redirect nua
        vsim -quiet -c -onfinish stop -l log/sim_${test}.log work.test_bench +TESTNAME=$test
        run -all
        quit -sim
        
        set run_date [clock format [clock seconds] -format "%H:%M:%S %b %d %Y"]
        
        set is_pass 0
        if {[file exists log/sim_${test}.log]} {
            set log_fp [open log/sim_${test}.log r]
            set log_content [read $log_fp]
            close $log_fp
            if {[regexp -nocase {PASSED} $log_content]} {
                set is_pass 1
            }
        }

        # LUU DONG KET QUA VAO BIEN SUMMARY_TABLE (Chua in ra ngay)
        if {$is_pass} {
            incr passed_cnt
            append summary_table [format "| %-30s | %-22s | %-8s |\n" $test $run_date "PASSED"]
        } else {
            append summary_table [format "| %-30s | %-22s | %-8s |\n" $test $run_date "FAILED"]
            append failed_list ">>> Kiem tra lai file log: log/sim_${test}.log\n"
        }
    }

    # ===================================================================
    # IN BANG TONG KET RA MAN HINH SAU KHI CHAY XONG TAT CA
    # ===================================================================
    echo "\n\n====================================================================="
    echo "                        BANG TONG KET REGRESSION                     "
    echo "====================================================================="
    echo "+--------------------------------+------------------------+----------+"
    echo [format "| %-30s | %-22s | %-8s |" "PAT_NAME" "RUN_DATE" "RESULT"]
    echo "+--------------------------------+------------------------+----------+"
    # In toan bo noi dung bang da gom duoc
    echo -nonewline $summary_table
    echo "+--------------------------------+------------------------+----------+"
    
    set remain [expr {$total_cnt - $passed_cnt}]
    echo "TOTAL/PASSED/REMAIN: $total_cnt/$passed_cnt/$remain"
    
    if {$remain != 0} {
        echo "\n==================== ERROR SUMMARY ===================="
        echo -nonewline $failed_list
        echo "=======================================================\n"
    } else {
        echo "\n >>> XUAT SAC! TAT CA CAC TESTCASE DEU PASSED! <<<\n"
    }
}
# ------------------------------------------------------------------------------
# 2.6. LUỒNG CHẠY REGRESSION KÈM COVERAGE (VERILOG)
# ------------------------------------------------------------------------------
proc regress_cov_v {} {
    echo "\n====================================================================="
    echo "           BAT DAU CHAY REGRESSION & COVERAGE (VERILOG)              "
    echo "====================================================================="

    if {![file exists pat.list]} {
        echo "Loi: Khong tim thay file pat.list trong thu muc hien tai!"
        return
    }

    # Tao thu muc hung log va bao cao
    file mkdir log
    file mkdir coverage

    quit -sim
    if {![file exists work]} { vlib work; vmap work work }
    
    # Bien dich RTL kem co lay coverage (+cover=bcesft)
    vlog -quiet +cover=bcesft ../rtl/*.v

    set total_cnt 0
    set passed_cnt 0
    set failed_list ""
    set summary_table ""

    set fp [open pat.list r]
    set lines [split [string map {\r ""} [read $fp]] "\n"]
    close $fp

    foreach test $lines {
        set test [string trim $test]
        if {$test == "" || [regexp {^#} $test]} { continue }

        incr total_cnt
        echo "\n---> Dang chay mo phong (Coverage): $test ..."

        file copy -force ../tb_v/${test}.v run_test.v
        
        # Bien dich testbench kem co coverage
        vlog -sv -quiet +cover=bcesft ../tb_v/testbench.v
        
        # Chay mo phong voi co coverage (-coverage)
        vsim -quiet -c -coverage -voptargs="+acc+cover=bcesft" -onfinish stop -l log/sim_${test}.log work.test_bench +TESTNAME=$test
        
        run -all
        
        # Luu file ucdb cho tung testcase truoc khi thoat
        coverage save coverage/${test}.ucdb
        quit -sim
        
        set run_date [clock format [clock seconds] -format "%H:%M:%S %b %d %Y"]
        
        set is_pass 0
        if {[file exists log/sim_${test}.log]} {
            set log_fp [open log/sim_${test}.log r]
            set log_content [read $log_fp]
            close $log_fp
            if {[regexp -nocase {PASSED} $log_content]} {
                set is_pass 1
            }
        }

        if {$is_pass} {
            incr passed_cnt
            append summary_table [format "| %-30s | %-22s | %-8s |\n" $test $run_date "PASSED"]
        } else {
            append summary_table [format "| %-30s | %-22s | %-8s |\n" $test $run_date "FAILED"]
            append failed_list ">>> Kiem tra lai file log: log/sim_${test}.log\n"
        }
    }

    # IN BANG TONG KET SAU KHI CHAY XONG
    echo "\n\n====================================================================="
    echo "                        BANG TONG KET REGRESSION                     "
    echo "====================================================================="
    echo "+--------------------------------+------------------------+----------+"
    echo [format "| %-30s | %-22s | %-8s |" "PAT_NAME" "RUN_DATE" "RESULT"]
    echo "+--------------------------------+------------------------+----------+"
    echo -nonewline $summary_table
    echo "+--------------------------------+------------------------+----------+"
    
    set remain [expr {$total_cnt - $passed_cnt}]
    echo "TOTAL/PASSED/REMAIN: $total_cnt/$passed_cnt/$remain"
    
    if {$remain != 0} {
        echo "\n==================== ERROR SUMMARY ===================="
        echo -nonewline $failed_list
        echo "=======================================================\n"
    } else {
        echo "\n >>> XUAT SAC! TAT CA CAC TESTCASE DEU PASSED! <<<"
    }

    # ===================================================================
    # TONG HOP COVERAGE VA XUAT BAO CAO
    # ===================================================================
    echo "\n====================================================================="
    echo "                DANG XUAT BAO CAO COVERAGE (HTML & TEXT)             "
    echo "====================================================================="
    
    # Merge tat ca cac file ucdb lai thanh 1 file IP.ucdb
    vcover merge coverage/IP.ucdb coverage/*.ucdb
    
    # Xuat ra file Text chi tiet
    vcover report -zeros -details -code bcesft coverage/IP.ucdb -output coverage/detail_report.txt
    
    # Xuat ra giao dien HTML (dep va de doc nhat tren Windows)
    vcover report -details -code bcesft -testHitDataAll -html coverage/IP.ucdb -htmldir coverage/html_report
    
    echo "-> Bao cao HTML da duoc luu tai: coverage/html_report/index.html"
    echo "-> Bao cao Text da duoc luu tai: coverage/detail_report.txt"
    echo "=====================================================================\n"
}

# ------------------------------------------------------------------------------
# 3. LUỒNG CHẠY SYSTEMVERILOG TESTBENCH (Thư mục tb_sv)
# ------------------------------------------------------------------------------
proc run_sv {} {
    echo "\n--- \[SYSTEMVERILOG FLOW\] Dang bien dich moi truong OOP... ---"
    quit -sim
    
    if {![file exists work]} { vlib work; vmap work work }

    # 1. Biên dịch RTL và Interface trước
    vlog -sv ../tb_sv/apb_timer_if.sv
    vlog ../rtl/*.v
    
    # 2. Biên dich file Top (Kèm cờ Coverage và Include path)
    vlog -sv +cover=bcesft +incdir+../tb_sv ../tb_sv/tb_timer_top.sv
            
    echo "--- \[SYSTEMVERILOG FLOW\] Bat dau mo phong ---"
    
    # Chạy mô phỏng (Thay thế lệnh vsim cũ bằng lệnh vsim có coverage)
    vsim -coverage -sv_seed random -voptargs="+acc+cover=bcesft" -onfinish stop work.tb_timer_top
    
    # Kéo các tín hiệu của Interface ra màn hình
    add wave -position insertpoint sim:/tb_timer_top/vif/*
    radix -hexadecimal
    
    run -all
}

# ------------------------------------------------------------------------------
# 4. LUỒNG XEM COVERAGE TRỰC TIẾP TRÊN GUI (ĐỂ LÀM EXCLUDE/WAIVER)
# ------------------------------------------------------------------------------
proc view_cov {} {
    echo "\n====================================================================="
    echo "             MO GIAO DIEN COVERAGE TRUC TIEP TREN QUESTA             "
    echo "====================================================================="
    
    # Kiem tra xem file IP.ucdb da duoc sinh ra tu buoc regress chua
    if {![file exists coverage/IP.ucdb]} {
        echo "Loi: Khong tim thay file coverage/IP.ucdb!"
        echo "Hay chay lenh 'regress_cov_v' de thu thap data truoc nhe."
        return
    }

    quit -sim
    
    # Mo file ucdb len giao dien QuestaSim
    vsim -viewcov coverage/IP.ucdb
    
    # Hien thi cac cua so danh cho Coverage
    view coverage
    
    echo "\n---> Da mo Coverage! Ban co the double-click vao cac module de xem chi tiet."
    echo "---> De Exclude: Chon dong bi miss -> Right Click -> Exclude."
}

# ==============================================================================
# HƯỚNG DẪN SỬ DỤNG
# ==============================================================================
echo ""
echo "====================================================================="
echo "           SCRIPT DIEU HUONG TESTBENCH DA DUOC NAP THANH CONG        "
echo "====================================================================="
echo " Cach su dung (Go lenh vao Transcript):"
echo ""
echo " >> Chay luong Verilog cu:"
echo "    run_v <ten_testcase>    (Vi du: run_v apb_protocol_chk)"
echo "    regress_v               (Chay toan bo test trong pat.list va in bang)"
echo ""
echo " >> Chay Coverage tren Verilog cu:"
echo "     regress_cov_v"
echo ""
echo " >> Chay luong SystemVerilog OOP moi:"
echo "    run_sv                  (Chay random test)"
echo ""
echo "    view_cov                (Mo file .ucdb tren GUI de lam Exclude)"
echo ""
echo " >> Don dep rac:"
echo "    clean"
echo "====================================================================="
echo ""