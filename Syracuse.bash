#!/bin/bash

#Function displaying help for the user
help() {
  echo "
Syracuse

Usage: ./Syracuse.bash <min> <max>

  -h, --help  Help display help message
  *   Help

Example:
  ./Syracuse.bash 1 100
"
  exit 1
}

#Array containing the entered parameters
PARAM=()

#Function for creating data and tmp directories
#These directories will store files containing values to create graphs
makeDir(){
  #If the file exist, we delete it
  if [ -d data ]
  then
      rm -r data
  fi
  #Then we recreate it to make sure there are no unnecessary files
  mkdir data
  mkdir data/tmp
}

#Fonction to separate ouput files of the C programm
#Each file is separated in 4 parts : n/Un values, the maximum altitude, the flying duration and the duration in altitude
calcul(){
  for var in `seq ${PARAM[0]} ${PARAM[1]}`
  do
      #We run the C program for an input value and we indicate the name of the ouput file
      bin/main $var f$var.dat

      #We get the part of the file that contains the n/Un values, and we copy it in a new file
      LINE_COUNT=`wc -l data/f$var.dat | cut -d' ' -f1`
      LINE_COUNT=`expr ${LINE_COUNT} - 4`
      tail -n +2 data/f$var.dat | head -n $LINE_COUNT > data/tmp/f${var}_un.dat

      #We get the maximum altitude and we copy it in a new file
      altimax=`tail -n3 data/f$var.dat | head -n1 | cut -d'=' -f2`
      echo "$var $altimax" >> data/tmp/altimax.dat

      #We do the same thing for other values
      dureevol=`tail -n2 data/f$var.dat | head -n1 | cut -d'=' -f2`
      echo "$var $dureevol" >> data/tmp/dureevol.dat

      dureealtitude=`tail -n1 data/f$var.dat | cut -d'=' -f2`
      echo "$var $dureealtitude" >> data/tmp/dureealtitude.dat
  done
}

#Function creating the 4 requested graphs
#We call a gnuplot program for each graph
chart(){

  #The program get the input parameters, set up the graph parameters, then creates the function for each value between the minimum and the maximum
  gnuplot -c gnuplot/un.ps "${PARAM[0]}" "${PARAM[1]}" 2>/dev/null

  #The process is very similar for the 3 other graphs
  gnuplot gnuplot/altimax.ps 2>/dev/null
  gnuplot gnuplot/dureevol.ps 2>/dev/null
  gnuplot gnuplot/dureealtitude.ps 2>/dev/null
}

#Function to group together every graph in a unique directory
move_chart(){
  #We delete the directory if it exists, then we recreate it to avoid mixing graphs between multiple use of the programm
  if [ -d result ]
  then
      rm -r result
  fi
  mkdir result

  #We move each graph in the directory
  mv valeurs.jpeg result
  mv altimax.jpeg result
  mv dureealtitude.jpeg result
  mv dureevol.jpeg result
}

#Function to group together every information files in a unique directory, with the graphs
move_data(){
  mv data/tmp/altimax.dat result
  mv data/tmp/dureealtitude.dat result
  mv data/tmp/dureevol.dat result
  mv data/synthese-${PARAM[0]}-${PARAM[1]}.txt result 
}

#Function to compile the C program if the executable doesn't exist
make_main() {
  if [ ! -d obj ]
  then
    mkdir obj
  fi
  if [ ! -d bin ]
  then
    mkdir bin
  fi
  make -s -f Makefile 2>/dev/null
  chmod -R +x "./bin/"
}

#Case if the two parameters are equal
equal(){
  #We get the maximum altitude and draw the graph with points only
    gnuplot -c gnuplot/altimax_egal.ps 2>/dev/null
  #We do the same thing for other values
    gnuplot -c gnuplot/dureevol_egal.ps 2>/dev/null
    gnuplot -c gnuplot/dureealtitude_egal.ps 2>/dev/null
  #We draw the graph with lines
    gnuplot -c gnuplot/un_egal.ps ${PARAM[0]} ${PARAM[1]} 2>/dev/null
} 

#Function to synthetise the data
synth(){

  #We get the values that we need
  VAL=`cut -d' ' -f2 data/tmp/$1`
  MIN=`head -n1 data/tmp/$1 | cut -d' ' -f2`
  MAX=$MIN
  MOY=0
  COUNT=0

  #We check the values to get the minimum value, the maximum and the average
  for i in $VAL
  do
    if [ $i -lt $MIN ]
    then
      MIN=$i
    fi
    if [ $i -gt $MAX ]
    then
      MAX=$i
    fi
    MOY=`expr $MOY + $i`
    COUNT=`expr $COUNT + 1`
  done

  MOY=`expr $MOY / $COUNT`

  #Finally, we create the file with the synthetised data, and we write them in it
  touch data/synthese-${PARAM[0]}-${PARAM[1]}.txt
  echo "$1 : MIN=$MIN ; MAX=$MAX ; MOY=$MOY" >> data/synthese-${PARAM[0]}-${PARAM[1]}.txt
}

#Function that calls all other functions of the program
verify() {
  #We check that there are 2 parameters, and that the first one is lower or equal to the second one
  if [[ ${#PARAM[*]} -eq 2 && ${PARAM[0]} -le ${PARAM[1]} ]]
  then
    clear
    echo "Initialization..."
    make_main 
    makeDir
    echo "Calculation of the values of the sequence..."
    calcul
    echo "Creation of graphs..."
    #We use different gnuplot programms depending on the input parameters
    if [ ${PARAM[0]} -eq ${PARAM[1]} ]
    then
      equal
    else
      chart
    fi
    echo "Synthesising the data..."
    synth altimax.dat
    synth dureealtitude.dat
    synth dureevol.dat
    echo "Finalization..."
    move_chart
    move_data
    rm -rf data
    echo "Done !"
    tar -czf "Syracuse_[${PARAM[0]}-${PARAM[1]}]_result" result/
    exit 1
  #If that's not the case, we display the help
  else
    clear
    echo "FR : Le nombre de valeurs entrées n'est pas égal à 2 OU le premier paramètre est plus grand que le second"
    echo "EN : The number of input values isn't equal to 2 OR the first parameter is greater than the second"
    help
  fi
}

#Verification of the input parameters
for a in "$@"
do 
  case "$a" in 
    #If there's "-h" or "--help" anywhere in the command line, we display the help
    "-h"|"--help")
        clear
        help
      ;;
    #If that's not the case, we check if the input parameters are correct
    *)
      #The first part of the "if" checks if the input values are integer. The second part checks that those values are greater than 0
      if [ "$a" -eq "$a" -a $a -gt 0 ] 2>/dev/null
      then
        #If the value is correct, we put it in the array
        PARAM+=($a)
      else
        #Otherwise, we display the help
        clear
        echo "FR : Une des valeurs entrées n'est pas un entier OU plus grande ou égale à 1"
        echo "EN : One of the input value isn't an integer OR greater than or equal to 1"
        help
      fi
      ;;
  esac 
done

#Finaly, we call the global function of the program
verify