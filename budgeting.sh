#!/bin/bash
DATAFILENAME=~/ToolData/output.txt
DATAFOLDER=~/ToolData

function budgeting() {

  if [ $# -eq 0 ]; then
    echo "Correct usage is budgeting -[options] [option inputs]. Do budgeting --help for help"
    return
  fi

  OPTIONS=$1

  case $OPTIONS in

    --help)
    echo "
    Command Options:
    budgeting -a [item] [cost] adds a new transaction.
Transactions are stored in $DATAFILENAME

    budgeting -P prints all prior transactions

    budgeting -p [date options] prints all transactions that match the category.
Date options can contain d=DD, m=MM, and/or y=YYYY seperated by spaces where
DD is the day, MM is the month, and YYYY is the year to be printed.
An example command is budgeting -p \"d=01 m=01 y=2022\" which would give
all payments from the 1st of January, 2022

    budgeting -S sums up the amounts of all prior transactions

    budgeting -S [item] sums up the amounts of all prior
transactions with item name of [item] (input in budgeting -a)

    budgeting -s [date options] sums up the amounts of all prior
transactions that fit within [date options] as explained in budgeting -p

    budgeting -s [date options] [item] sums up the amounts of all prior
transactions that fit within [date options] as explained in budgeting -p
and [item] as explained in budeting -S

    budgeting -R will remove all prior transactions

    budgeting -r will remove the last transaction
    "
    return
    ;;

    -a)
    if [ ! -d "$DATAFOLDER" ]; then
      mkdir "$DATAFOLDER"
    fi

    local DAY=$(date "+%d")
    local MONTH=$(date "+%m")
    local YEAR=$(date "+%Y")

    echo "$DAY-$MONTH-$YEAR $2 $3 " | tee -a "$DATAFILENAME"
    return
    ;;

    -P)
    cat "$DATAFILENAME"
    return
    ;;

    -p)
    if [ ${#2} -eq 0 ]; then # Give
      echo "No clarifying string given. If you wish to print all entries use budgeting -P.
For more info on budgeting -p use budgeting --help"
      return
    fi

    # Set $DAY $MONTH and $YEAR to contain the user-entered values or -1 if no values are supplied
    __findDateFromStr "$2"


    if [ $DAY -eq -1 ] && [ $MONTH -eq -1 ] && [ $YEAR -eq -1 ]; then
      echo "No valid arguments given. Please use budgeting --help for more information on
this command"
      return
    fi

    if [ -f "$DATAFILENAME" ]; then #Import data if there is any
      DATA=$(cat "$DATAFILENAME")
    else
      echo "No avaliable data file"
      return
    fi
    IFS=$'\n\t '
    DATAARR=($DATA) # Turn the taken data file into an array of entries

    IFS='-' # set IFS to auto-seperate the different elements of the date into an array
    for (( i = 0; i < ${#DATAARR[@]}; i = i+3 )); do
      DATEARR=(${DATAARR[i]}) # Break apart the day, month, and year of the date
      if [[ ${DATEARR[0]} == $DAY || $DAY == "-1" ]] && [[ ${DATEARR[1]} == $MONTH || $MONTH == "-1" ]] && [[ ${DATEARR[2]} == $YEAR || $YEAR == "-1" ]]; then
        echo "${DATAARR[$i]} ${DATAARR[$i+1]} ${DATAARR[$i+2]}"
      fi
    done
    IFS=$'\n\t ' # set IFS to default values
    return
    ;;

    -R)
    read -p "This will remove all of your data. Are you sure? Type Y to confirm " -n 1 -r
    echo
    if [[ $REPLY == Y ]]
    then
      rm "$DATAFILENAME"
      touch "$DATAFILENAME"
    fi
    return
    ;;

    -r)
    IFS=$'\n\t '

    DATA=$(cat "$DATAFILENAME") #Grab the data from the file
    DATAARR=($DATA) #Turn the data into an array seperated by spaces
    ENDIDX=$(( ${#DATAARR[@]} - 4 )) # 0 Based indexing so data should go from 0-(${#DATAARR[@]} - 1) and excluding the last line (3 entries) -4 instead of -1

    #If there is less than one line from the start (3 entries) then remove all data by resetting the file
    if [ $ENDIDX -lt 0 ]; then
      rm "$DATAFILENAME"
      touch "$DATAFILENAME"
    fi

    #Rewrite the data excluding the last line
    for (( i = 0; i<=$ENDIDX; i = i+3 )); do
      if [ $i -eq 0 ]; then
        echo "${DATAARR[i]} ${DATAARR[i+1]} ${DATAARR[i+2]}" | tee "$DATAFILENAME" > "$DATAFOLDER/temp.txt";
      else
        echo "${DATAARR[i]} ${DATAARR[i+1]} ${DATAARR[i+2]}" | tee -a "$DATAFILENAME" > "$DATAFOLDER/temp.txt";
      fi
    done
    return
    ;;

    -S)

    ##SETUP
    if [ -f "$DATAFILENAME" ]; then #Import data if there is any
      DATA=$(cat "$DATAFILENAME")
    else
      echo "No avaliable data file"
      return
    fi
    IFS=$'\n\t '
    DATAARR=($DATA) # Turn the taken data file into an array of entries
    COUNT=0 # Set the counter variable


    if [ $# -eq 1 ]; then # If there is no specific item restriction
      for (( i = 0; i < ${#DATAARR[@]}; i = i+3 )); do
        COUNT=$(echo "$COUNT+${DATAARR[i+2]}" | bc) # Sums up all of the values
      done

    else # If there is an item restriction
      for (( i = 0; i < ${#DATAARR[@]}; i = i+3 )); do
        if [[ $2 == ${DATAARR[i+1]} ]]; then # if the passed item name matches the item name of the entry
          COUNT=$(echo "$COUNT+${DATAARR[i+2]}" | bc) # Sums up all of the values
        fi
      done
    fi

    echo $COUNT # Gives the value output
    return
    ;;

    -s)

    ##SETUP
    if [ -f "$DATAFILENAME" ]; then #Import data if there is any
      DATA=$(cat "$DATAFILENAME")
    else
      echo "No avaliable data file"
      return
    fi
    IFS=$'\n\t '
    DATAARR=($DATA) # Turn the taken data file into an array of entries
    COUNT=0 # Set the counter variable

    # Set $DAY $MONTH and $YEAR to contain the user-entered values or -1 if no values are supplied
    __findDateFromStr "$2"

    if [ $# -eq 1 ]; then

      echo "Too few arguments given. Check budgeting --help for help"
      return

    elif [ $# -eq 2 ]; then

      IFS='-' # set IFS to auto-seperate the different elements of the date into an array
      for (( i = 0; i < ${#DATAARR[@]}; i = i+3 )); do
        DATEARR=(${DATAARR[i]}) # Break apart the day, month, and year of the date
        if [[ ${DATEARR[0]} == $DAY || $DAY == "-1" ]] && [[ ${DATEARR[1]} == $MONTH || $MONTH == "-1" ]] && [[ ${DATEARR[2]} == $YEAR || $YEAR == "-1" ]]; then
          COUNT=$(echo "$COUNT+${DATAARR[i+2]}" | bc)
        fi
      done
      IFS=$'\n\t ' # set IFS to default values

    else

      IFS='-' # set IFS to auto-seperate the different elements of the date into an array
      for (( i = 0; i < ${#DATAARR[@]}; i = i+3 )); do
        DATEARR=(${DATAARR[i]}) # Break apart the day, month, and year of the date
        if [[ ${DATEARR[0]} == $DAY || $DAY == "-1" ]] && [[ ${DATEARR[1]} == $MONTH || $MONTH == "-1" ]] && [[ ${DATEARR[2]} == $YEAR || $YEAR == "-1" ]] && [[ $3 == ${DATAARR[i+1]} ]]; then
          COUNT=$(echo "$COUNT+${DATAARR[i+2]}" | bc)
        fi
      done
      IFS=$'\n\t ' # set IFS to default values

    fi

    echo $COUNT
    return
    ;;

    *)
    echo Unrecognized Command. Do budgeting --help to view commands
    return
    ;;

  esac
}

function __findDateFromStr() {

  OIFS="$IFS"
  IFS=$'\n\t '

  STRINGARR=($1)
  # Set default values for whichever values are not user-specified
  DAY=-1
  MONTH=-1
  YEAR=-1

  for (( i = 0; i < ${#STRINGARR[@]}; i++ )); do
    PARTSTR=${STRINGARR[i]}
    if [ ${PARTSTR:0:2} == "d=" ]; then
      DAY=${PARTSTR:2:4}
    elif [ ${PARTSTR:0:2} == "m=" ]; then
      MONTH=${PARTSTR:2:4}
    elif [ ${PARTSTR:0:2} == "y=" ]; then
      YEAR=${PARTSTR:2:6}
    fi
  done

  IFS="$OIFS"

}
