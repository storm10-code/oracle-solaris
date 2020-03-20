#!/bin/sh 
#----------------------------------------------------------------------------------------
# Copyright (C) 2008-2017 by Dell EMC Corporation 
# All rights reserved.
#----------------------------------------------------------------------------------------
# File name: inq.sh
# Description: Runs SCSI inquiry utility provided with the emcgrab
#
# Updated to reflect support for the latest inq. Reference the
# <os>_inq_version_info.txt file in ./emcgrab/tools/bin directory
# for current inq versions
#
###### Revision history ######
#----------------------------------- Revision History -----------------------------------
#--------------------------------------- v4.7.11 -----------------------------------------
# FEATURE-1635: add inq 8.4.0.7 to all Operating System grabs
#--------------------------------------- v4.7.10 -----------------------------------------
# FEATURE-1163: add inq 8.4.0.3 to all Operating System grabs
#--------------------------------------- v4.7.9 -----------------------------------------
# FEATURE-1229: added inq -native to collection
#--------------------------------------- v4.6.8 -----------------------------------------
# EMCGRAB-620: Xtremio ad VPLEX commands
#--------------------------------------- v4.6.4 -----------------------------------------
# EMCGRAB-569: Added new inq commands for virtual disks
#--------------------------------------- v4.6.0 -----------------------------------------
# GERS_4831: Add condition for running the "powerprotect" command
#--------------------------------------- v4.5.1 -----------------------------------------
# GERS_4483: Modify output message for the -noinqDBG option or LITE mode
#--------------------------------------- v4.4.5 -----------------------------------------
# GERS_2333: Add automatic debug for inquiries in FULL mode
#----------------------------------------------------------------------------------------

RC=0
SCRIPT_TMP=${EMC_TMP}/${BASENAME}
NAME="inq - inquiry"

RUNTIME=420

# Added as a separate item for force usage of EMC's inq supplied with EMC Grab
# inq is compressed, therefore needs to be uncompressed before running

if [ ! -f ${SCRIPTS}/tools.main ]
then 
	echo "Unable to source file tools.main....exiting"
	RC=2
	exit ${RC}
else
	. ${SCRIPTS}/tools.main
fi

check_dir

PWR_CMD="powerprotect"
PC_EXIST=`which ${PWR_CMD} 2>&1 | awk -f ${AWK}/check_exe.awk`
export PC_EXIST

#       execute INQ
exec_inq()
{
    printf "\n\nCollecting ${NAME} Information\n" | tee -a ${RPT}
    if [ -x ${BIN}/${INQ} ]; then
        DIR_SAVE=`pwd`
        cd ${BIN}

        run_single_command "${INQ} -no_dots"
        run_single_command "${INQ} -no_dots -et"
        run_single_command "${INQ} -no_dots -btl"
        run_single_command "${INQ} -no_dots -compat"
        run_single_command "${INQ} -no_dots -native"

        if [ ${PC_EXIST} -eq 1 ]; then
            run_single_command "powerprotect '${INQ} -celerra'"
        else
            printf "\npowerprotect command not found...\n" | tee -a ${RPT} ${ERR_RPT}
        fi

        # Specific commands only available with later versions of INQ

        if [ ${INQ_MODE} -eq 0 ]; then
	    run_single_command "${INQ} -hba"

	    # Lets read the original base inq output
	    SOURCE_FILE="${SCRIPT_TMP}/${INQ}_-no_dots.txt"
		
		run_single_command "${INQ} -no_dots -mapinfo"
		
	    if [ -f ${SOURCE_FILE} ]; then # Determine what products are defined 

	        grep OPEN ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 -a -x ${SCRIPTS}/hdsdevs ]; then # There are Hitachi devices found. Run script hdsdevs.sh
		    run_single_command "hdsdevs"
		    run_single_command "${INQ} -no_dots -f_hds"
		    run_single_command "${INQ} -no_dots -hds_wwn"
		fi

		grep DGC ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are Data General (Clariion) devices found.  
		    run_single_command "${INQ} -no_dots -clar_wwn"
		    run_single_command "${INQ} -no_dots -f_clariion"
		fi

		grep SYMMETRIX ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are Symmetrix  devices found.  
		    run_single_command "${INQ} -no_dots -f_emc"
		    run_single_command "${INQ} -no_dots -sym_wwn"
		fi

		grep Invista ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are Invista/VPLEX  devices found.  
		    run_single_command "${INQ} -no_dots -f_invista"
		    run_single_command "${INQ} -no_dots -invista_wwn"
		fi
		
		grep VPLEX ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are VPLEX  devices found.  
		    run_single_command "${INQ} -no_dots -f_vplex"
		    run_single_command "${INQ} -no_dots -vplex_wwn"
		fi
		
		grep XtremIO ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are VPLEX  devices found.  
		    run_single_command "${INQ} -no_dots -f_xtremio"
		    run_single_command "${INQ} -no_dots -xtremio_wwn"
		fi

		grep IBM ${SOURCE_FILE} > /dev/null 2>&1 
			
		if [ $? -eq 0 ]; then # There are IBM  devices found.  
		    run_single_command "${INQ} -no_dots -f_shark"
		    run_single_command "${INQ} -no_dots -shark_wwn"
		fi

		grep VDASD ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are AIX virtual devices found.  
		    run_single_command "${INQ} -emcvdasd"
		    run_single_command "${INQ} -emcvdasd -clar_wwn"
		    run_single_command "${INQ} -emcvdasd -sym_wwn"
		    run_single_command "${INQ} -emcvdasd -xtremio_wwn"
		fi
	    fi
	fi

	cd ${DIR_SAVE}

	sleep 5			
else
	printf "\n${BIN}/${INQ} not found" | tee -a ${RPT}
fi
}

exec_inq_debug()
{
    printf "\n\nCollecting ${NAME} Information with DEBUG ON\n" | tee -a ${RPT}

    if [ -x ${BIN}/${INQ} ]; then
	DIR_SAVE=`pwd`
	cd ${BIN}

	run_single_command "${INQ} -no_dots" "${INQ}_-no_dots_DEBUG"
	run_single_command "${INQ} -no_dots -et" "${INQ}_-no_dots_-et_DEBUG"
	run_single_command "${INQ} -no_dots -btl" "${INQ}_-no_dots_-btl_DEBUG"
	run_single_command "${INQ} -no_dots -compat" "${INQ}_-no_dots_-compat_DEBUG"

        if [ ${PC_EXIST} -eq 1 ]; then
	    run_single_command "powerprotect '${INQ} -celerra'" "powerprotect_${INQ}_-celerra_DEBUG"
        else
            printf "\npowerprotect command not found...\n" | tee -a ${RPT} ${ERR_RPT}
        fi

	# Specific commands only available with later versions of INQ

	if [ ${INQ_MODE} -eq 0 ]; then
	    run_single_command "${INQ} -hba" "${INQ}_-hba_DEBUG"

	    # Lets read the original base inq output
	    SOURCE_FILE="${SCRIPT_TMP}/${INQ}_-no_dots.txt"

	    if [ -f ${SOURCE_FILE} ]; then # Determine what products are defined

		grep OPEN ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 -a -x ${SCRIPTS}/hdsdevs ]; then # There are Hitachi devices found. Run script hdsdevs.sh
		    run_single_command "${INQ} -no_dots -f_hds" "${INQ}_-no_dots_-f_hds_DEBUG"
		    run_single_command "${INQ} -no_dots -hds_wwn" "${INQ}_-no_dots_-hds_wwn_DEBUG"
		fi

		grep DGC ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are Data General (Clariion) devices found.  
		    run_single_command "${INQ} -no_dots -clar_wwn" "${INQ}_-no_dots_-clar_wwn_DEBUG"
		    run_single_command "${INQ} -no_dots -f_clariion" "${INQ}_-no_dots_-f_clariion_DEBUG"
		fi

		grep SYMMETRIX ${SOURCE_FILE} > /dev/null 2>&1 

		if [ $? -eq 0 ]; then # There are Symmetrix  devices found.  
		    run_single_command "${INQ} -no_dots -f_emc" "${INQ}_-no_dots_-f_emc_DEBUG"
		    run_single_command "${INQ} -no_dots -sym_wwn" "${INQ} -no_dots -sym_wwn_DEBUG"
		fi

		grep IBM ${SOURCE_FILE} > /dev/null 2>&1 

               if [ $? -eq 0 ]; then # There are IBM  devices found.
                   run_single_command "${INQ} -no_dots -f_shark" "${INQ}_-no_dots_-f_shark_DEBUG"
                   run_single_command "${INQ} -no_dots -shark_wwn" "${INQ}_-no_dots_-shark_wwn_DEBUG"
               fi

               grep Invista ${SOURCE_FILE} > /dev/null 2>&1

               if [ $? -eq 0 ]; then # There are Invista/VPLEX  devices found.
                   run_single_command "${INQ} -no_dots -f_invista" "${INQ}_-no_dots_-f_invista_DEBUG"
                   run_single_command "${INQ} -no_dots -invista_wwn" "${INQ}_-no_dots_-invista_wwn_DEBUG"
               fi
           fi
        fi

        cd ${DIR_SAVE}

        sleep 5
    else
        printf "\n${BIN}/${INQ} not found" | tee -a ${RPT}
    fi
}

exec_inq

if [  ${NOINQDBG} -eq 1 -a "${LITE}" = "ON" ]; then
    printf "\nNo INQ debug information collected (LITE mode)\n" | tee -a ${RPT} ${ERR_RPT}
elif [ ${NOINQDBG} -eq 1 -a "${LITE}" = "OFF" ]; then
    printf "\nNo INQ debug information collected (Run.inqdebug=no option is set)\n" | tee -a ${RPT} ${ERR_RPT}
else
    SDEBUG=ALL
    export SDEBUG

    exec_inq_debug

    SDEBUG=""
    export SDEBUG
fi

printf "\n" | tee -a ${RPT}

exit ${RC}