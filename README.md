#Laser Program

##Made by Dr. Tyrone Vincent and Henry Dau
##Last edit made May 24th, 2016

##Overview
This program interfaces MATLAB with an Arduino Mega and an OPHIR USB Interface
to control the power output of a laser. The important files are guiserial_v2
and Motor_Controller_v3. guiserial_v2 opens a GUI for the user to control
the arduino and read data from both the laser and the arduino. For correct
functionality, an Arduino Mega must be connected to COM6 (can be edited in the code)
and an OPHIR USB Interface must be connected via USB to the computer. The
previously mentioned GUI allows the user to rotate three motors independently
which control the power ouput of the laser. The GUI allows the user to read from
a file which will move the motors to specific points at specific points in time,
or run without a file and manually control the motors. The program will display
a graph of the laser power while the program is running and write all program
data during a run to a file named 'log_runX.txt' where X is a unique integer
identifier (e.g. - 'log_run1.txt', 'log_run2.txt', etc.). The program will
retrieve laser and arduino data based on a timer callback with a default
period of 0.5 seconds.

##Files

###guiserial_v2

###Motor_Controller_v3

###instr.txt
The file read from to move the motors automatically. Requires 4 columns:

time_stamp - The time which the motors should move to the set point
motor_1_setpoint - The setpoint (in degrees) of the motor 
motor_2_setpoint - The setpoint (in degrees) of the motor 
motor_3_setpoint - The setpoint (in degrees) of the motor 

Note that the time stamps must be in sequental order.

###log_runX.txt
This file is not included in the repository, but is created by default at
the end of every data collection run. The file contains 19 columns as follows:

time_stamp - The time during the programs execution that the data was taken
laser_power - The Watts of the laser at this point in time
motor_1_pos_without_backlash - Motor 1's setpoint without the backlash calculation
motor_2_pos_without_backlash - Motor 2's setpoint without the backlash calculation
motor_3_pos_without_backlash - Motor 3's setpoint without the backlash calculation
motor_1_setpoint - Motor 1's setpoint with the backlash calculation
motor_1_position - Motor 1's position
motor_1_command - The PWM command sent to motor 1 (ranges from 0-255)
motor_1_err - The error between the motor setpoint and position (used to calc command)
motor_2_setpoint - Motor 2's setpoint with the backlash calculation
motor_2_position - Motor 2's position
motor_2_command - The PWM command sent to motor 2 (ranges from 0-255)
motor_2_err - The error between the motor setpoint and position (used to calc command)
motor_3_setpoint - Motor 3's setpoint with the backlash calculation
motor_3_position - Motor 3's position
motor_3_command - The PWM command sent to motor 3 (ranges from 0-255)
motor_3_err - The error between the motor setpoint and position (used to calc command)
execution_time - The time it took for the arduino program to execute (in microseconds)
                 NOTE* - The arduino program runs every 10 milliseconds
Error - Debugging boolean indicating wheather the encoders have moved an impossible
        amount. Can be ignored when plotting the data.

