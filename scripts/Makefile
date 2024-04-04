DIR=$(shell pwd)
proj_folder=$(shell dirname ${DIR})
DATE=$(shell date +%Y%m%d)
#OUTPUTS=../vcs_sim_${DATE}

xil_defaultlib = ${OUTPUTS}/xil_defaultlib
COMP_OPTS=-full64
COMP_OPTS+=+define+FOR_SIM+USE_DUT
COMP_OPTS+=+incdir+${proj_folder}/testbench+${proj_folder}/includes
COMP_OPTS+=+warn=[no]IPDASP,none 
COMP_OPTS+=-sverilog 
COMP_OPTS+=-timescale=1ns/1ps 

VERDI_OPT = +incdir+${DIR}/../testbench
VERDI_OPT+= +define+FOR_SIM+USE_DUT

vcs_opts=-full64 -debug_all -ucli  -licqueue -l elaborate.log -P ${VERDI_HOME}/share/PLI/VCS/linux64/novas.tab ${VERDI_HOME}/share/PLI/VCS/linux64/pli.a -Mupdate -j2 +rad +lint=TFIPC-L +neg_tchk
#vcs_opts+=-sdf typ:dwc_ahsata_u0:../fpga_proj/dwc_ahsata_synth/dwc_ahsata.sdf
top=i2c_tb
OUTPUTS=../work

#top=i2c_phy_tb
#OUTPUTS=../work/unitest

.PHONY:all
all : simdir comp elab sim

.PHONY:netlist_sim
netlist_sim : simdir synth_sim elab sim


# compile
.PHONY: comp
comp:
	cd ${OUTPUTS} && rm -rf xil_defaultlib
	cd ${OUTPUTS} && \
		export proj_folder=$(proj_folder) && \
		vlogan $(COMP_OPTS) +v2k -work xil_defaultlib -f $(proj_folder)/duv/$(top).f
	cd ${OUTPUTS} && vlogan $(COMP_OPTS) +v2k -work xil_defaultlib /home/zack/xilinx_vcs_sim/glbl.v

# elaborate
.PHONY: elab
elab:
	cd ${OUTPUTS} && vcs $(vcs_opts) xil_defaultlib.$(top) xil_defaultlib.glbl -o $(top)
	#cd ${OUTPUTS} && vcs $(vcs_opts) xil_defaultlib.$(top)  -o $(top)


.PHONY: simdir
simdir:
	test -d ${OUTPUTS} || mkdir -p ${OUTPUTS}
	echo "OTHERS = /home/zack/xilinx_vcs_sim/synopsys_sim.setup" > ${OUTPUTS}/synopsys_sim.setup
	echo "xil_defaultlib : ./xil_defaultlib" >> ${OUTPUTS}/synopsys_sim.setup
	echo "call {\$$fsdbDumpfile(\"${top}.fsdb\")}" >  ${OUTPUTS}/auto_run
	echo "call {\$$fsdbDumpvars(0, ${top})}" >> ${OUTPUTS}/auto_run
	echo "run" >> ${OUTPUTS}/auto_run

.PHONY: sim
sim:
	cd ${OUTPUTS} && ./$(top) -do ./auto_run -l sim.log


.PHONY: fl
fl:
	cd ../rtl && ls | sed "s:^:`pwd`/: "| grep '\.v' > filelist


.PHONY: verdi
verdi:
	export proj_folder=$(proj_folder) && \
	cd $(OUTPUTS) && verdi $(VERDI_OPT) -f $(proj_folder)/duv/$(top).f -ssf ${top}.fsdb &

.PHONY: test
test:
	@echo "${VERDI_HOME}"
	@echo "${DIR}"
	@echo "${proj_folder}"
	@echo "${DATE}"

