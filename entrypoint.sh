#! /bin/bash

debug_message() {
    echo "\033[35m
        ____  __________  __  ________   __  _______  ____  ______
       / __ \/ ____/ __ )/ / / / ____/  /  |/  / __ \/ __ \/ ____/
      / / / / __/ / __  / / / / / __   / /|_/ / / / / / / / __/   
     / /_/ / /___/ /_/ / /_/ / /_/ /  / /  / / /_/ / /_/ / /___   
    /_____/_____/_____/\____/\____/  /_/  /_/\____/_____/_____/   
    
    "
    echo -e "\033[35m\tINFO\t[GZ-CLASSIC]\tDEBUG_MODE IS SET. NOTHING WILL RUN"
}

if [ "x${SITL_TYPE}" != "xgazebo-classic" ]; then
    echo -e "\033[31m\tINFO\t[GZ-CLASSIC]\tINVALID SITL_TYPE."
    echo -e "\033[31m\tINFO\t[GZ-CLASSIC]\tSITL_TYPE FOR THIS CONTAINER MUST BE \033[32m\"gazebo-classic\"."
    exit 1
fi

if [ -z "${ROS_DOMAIN_ID}" ]; then
    ROS_DOMAIN_ID=0
fi

if [ -z "${HEADLESS}" ]; then
    HEADLESS=0
fi

if [ -z "${DEBUG_MODE}" ]; then
    DEBUG_MODE=0
fi

if [ -z "${EXPORT_ENV}" ]; then
    EXPORT_ENV=1
fi

# EXPORT ENVIRONMENT VARIABLES
PX4_SOURCE_DIR=/home/user/PX4-Autopilot
PX4_SIM_DIR=/home/user/PX4-Autopilot/Tools/simulation
PX4_BUILD_DIR=/home/user/PX4-Autopilot/build/px4_sitl_default
PX4_BINARY_DIR=/home/user/PX4-Autopilot/build/px4_sitl_default/bin

# DIRECTORY TO PX4 gazebo SITL WORLD/MODEL OBJECTS
PX4_GZ_WORLDS=${PX4_SIM_DIR}/gazebo-classic/sitl_gazebo-classic/worlds
PX4_GZ_MODELS=${PX4_SIM_DIR}/gazebo-classic/sitl_gazebo-classic/models

# SET GAZEBO RESOURCE PATH
# export GAZEBO_MODEL_PATH=${PX4_GZ_MODELS}:${GAZEBO_USER_MODEL_PATH}
source /usr/share/gazebo/setup.bash

# EXPORT GAEBZO RESOURCE PATH
export GAZEBO_RESOURCE_PATH=${GAZEBO_RESOURCE_PATH}:${PX4_GZ_WORLDS}:${GAZEBO_USER_RESOURCE_PATH}

# PREVENT GAZEBO FROM RUNNING WHEN RUNNING PX4 STACK
COMMENT_START=$(grep -wn "sitl_command=" ${PX4_SIM_DIR}/gazebo-classic/sitl_run.sh | cut -d: -f1)
COMMENT_END=$(grep -wn "popd >/dev/null" ${PX4_SIM_DIR}/gazebo-classic/sitl_run.sh | cut -d: -f1)

COMMENT_END=$(echo ${COMMENT_END} | tail -1)
COMMENT_END=$((${COMMENT_END} + 6))

sed -i "${COMMENT_START},${COMMENT_END}s/\(.*\)/#\1/g" \
    ${PX4_SIM_DIR}/gazebo-classic/sitl_run.sh

sed -i "s/-n \"\$HEADLESS\"/\$HEADLESS -eq 1/g" \
    ${PX4_SIM_DIR}/gazebo-classic/sitl_run.sh


# A. DEBUG MODE / SIMULATION SELCTOR
## CASE A-1: DEBUG MODE
if [ "${DEBUG_MODE}" -eq "1" ]; then

    debug_message

    ## A-1. EXPORT ENVIRONMENT VARIABLE?
    ### CASE A-1-1: YES EXPORT THEM
    if [ "${EXPORT_ENV}" -eq "1" ]; then

        #- GET LINE NUMBER TO START ADDING export STATEMENT
        COMMENT_BASH_START=$(grep -c "" /home/user/.bashrc)
        COMMENT_ZSH_START=$(grep -c "" /home/user/.zshrc)

        COMMENT_BASH_START=$(($COMMENT_BASH_START + 1))
        COMMENT_ZSH_START=$(($COMMENT_ZSH_START + 1))


        #- WTIE VARIABLED TO BE EXPORTED TO THE TEMPFILE
        echo "HEADLESS=${HEADLESS}" >> /tmp/envvar
        echo "GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH}" >> /tmp/envvar
        echo "ROS_DOMAIN_ID=${ROS_DOMAIN_ID}" >> /tmp/envvar

        #- ADD VARIABLES TO BE EXPORTED TO SHELL RC
        for value in $(cat /tmp/envvar)
        do
            echo ${value} >> /home/user/.bashrc
            echo ${value} >> /home/user/.zshrc
        done

        #- ADD export STATEMENT TO VARIABLES
        sed -i "${COMMENT_BASH_START},\$s/\(.*\)/export \1/g" \
            ${HOME}/.bashrc
        sed -i "${COMMENT_ZSH_START},\$s/\(.*\)/export \1/g" \
            ${HOME}/.zshrc

        #- REMOVE TEMPORARY FILE
        rm -f /tmp/envvar

    ### CASE A-1-2: NO LEAVE THEM CLEAN
    else
        echo -e "\033[31mINFO\t[GZ-CLASSIC]\tENVIRONMENT VARS WILL NOT BE SET"
    fi


## CASE A-2: SIMULATION MODE
else

    echo -e "\033[32mINFO\t[GZ-CLASSIC]\tRUNNING GAZEBO-CLASSIC SIMULATOR"

    # CREATE LOG DIRECTORY IF IT DOES NOT EXIST
    if [ ! -d "${HOME}/log" ]; then
        mkdir ${HOME}/log
    fi

    # IF GAZEBO LOG EXISTS, DELETE IT AND REMAKE IT
    if [ -f "${HOME}/log/gazeboRun" ]; then
        rm -rf ${HOME}/log/gazeboRun
    fi
    
    # ALLOW PERMISSION FOR PIXHAWK SERIAL PORT
    sudo chmod 666 /dev/${PIXHAWK_SERIAL_PORT}
    python3 /home/user/scripts/set_pixhawk_serial_port.py 
    
    cd /home/user/PX4-Autopilot
    source Tools/simulation/gazebo-classic/setup_gazebo.bash $(pwd) $(pwd)/build/px4_sitl_default \
    && gazebo /home/user/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/worlds/${SITL_WORLD}.world

    # CREATE EMPTY FILE TO LOG GAZEBO RUYN STATUS
    touch ${HOME}/log/gazeboRun

    # ${SITL_AIRFRAME} 

    # ${PX4_SIM_DIR}/gazebo-classic/sitl_run.sh \
    #     ${PX4_BINARY_DIR}/px4 \
    #     none \
    #     ${SITL_AIRFRAME} \
    #     ${SITL_WORLD} \
    #     ${PX4_SOURCE_DIR} \
    #     ${PX4_BUILD_DIR} > ${HOME}/log/gazeboRun

    if [ ! -z ${AIRSIM_IP} ]; then
        echo -e "\033[32mINFO\t[GZ-CLASSIC]\tAIRSIM_IP SET. STARTING AIRSIM BRIDGE..."
        /home/user/scripts/AirSimBridge >> /dev/null
    fi
fi

# KEEP CONTAINER ALIVE
sleep infinity



