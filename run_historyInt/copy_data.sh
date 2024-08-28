#!/bin/bash
# copy history files:
#file copied from:
OUTPUT_PATH='ZSTAT'
INPUT_PATH='../run_tutorial'

RUN_FOLDER=$(ls $INPUT_PATH | grep 'output_')

i_total_snap_file=0

for i_folder in $RUN_FOLDER
do
	echo $INPUT_PATH/$i_folder
	SNAP=$(ls $INPUT_PATH/$i_folder | grep 'la2duct0.f')
	i_local_snap=0
	for i_snap in $SNAP
	do
		((i_total_snap_file++))
		((i_local_snap++))
		printf -v N_FILE "%05d" $i_local_snap
	  COPY_FROM0=$INPUT_PATH/$i_folder/la2duct0.f$N_FILE
		echo $COPY_FROM0

	  printf -v LAST "%05d" $i_total_snap_file
	  COPY_TO0=$OUTPUT_PATH/la2duct0.f$LAST
		echo $COPY_TO0

	  cp $COPY_FROM0 $COPY_TO0

	done

done
