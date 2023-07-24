DIR=$(shell pwd)
proj_folder=$(shell dirname ${DIR})
DATE=$(shell date +%Y%m%d)
OUTPUTS=../work
#OUTPUTS=../vcs_sim_${DATE}

xil_defaultlib = ${OUTPUTS}/xil_defaultlib
COMP_OPTS=-full64
COMP_OPTS+=+define+FOR_SIM
COMP_OPTS+=+incdir+${DIR}/../testbench
COMP_OPTS+=+warn=[no]IPDASP,none 
COMP_OPTS+=-sverilog 
COMP_OPTS+=-timescale=1ns/1ps 

VERDI_OPT = +incdir+${DIR}/../testbench
VERDI_OPT+= +define+FOR_SIM

vcs_opts=-full64 -debug_all -ucli  -licqueue -l elaborate.log -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a -Mupdate -j2 +rad +lint=TFIPC-L +neg_tchk
#vcs_opts+=-sdf typ:dwc_ahsata_u0:../fpga_proj/dwc_ahsata_synth/dwc_ahsata.sdf
top=i2c_tb

.PHONY:all
all : simdir comp elab sim

.PHONY:netlist_sim
netlist_sim : simdir synth_sim elab sim

.PHONY: sim
sim:
	cd ${OUTPUTS} && ./$(top) -do ../scripts/auto_run -l sim.log

# elaborate
.PHONY: elab
elab:
	cd ${OUTPUTS} && vcs $(vcs_opts) xil_defaultlib.$(top) xil_defaultlib.glbl -o $(top)
	#cd ${OUTPUTS} && vcs $(vcs_opts) xil_defaultlib.$(top)  -o $(top)

# compile
.PHONY: comp
comp:
	cd ${OUTPUTS} && rm -rf xil_defaultlib
	cd ${OUTPUTS} && \
		export proj_folder=$(proj_folder) && \
		vlogan $(COMP_OPTS) +v2k -work xil_defaultlib -f ../duv/$(top).f
	cd ${OUTPUTS} && vlogan $(COMP_OPTS) +v2k -work xil_defaultlib /home/zack/xilinx_vcs_sim/glbl.v


.PHONY: simdir
simdir:
	test -d ${OUTPUTS} || mkdir -p ${OUTPUTS}
	echo "OTHERS = /home/zack/xilinx_vcs_sim/synopsys_sim.setup" > ${OUTPUTS}/synopsys_sim.setup
	echo "xil_defaultlib : ./xil_defaultlib" >> ${OUTPUTS}/synopsys_sim.setup

.PHONY: fl
fl:
	cd ../rtl && ls | sed "s:^:`pwd`/: "| grep '\.v' > filelist


.PHONY: verdi
verdi:
	export proj_folder=$(proj_folder) && \
	cd $(OUTPUTS) && verdi $(VERDI_OPT) -f ../duv/$(top).f &

.PHONY: test
test:
	@echo "${VERDI_HOME}"
	@echo "${DIR}"
	@echo "${proj_folder}"
	@echo "${DATE}"

