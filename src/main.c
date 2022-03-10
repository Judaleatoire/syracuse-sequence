// We include the header associated with the file
#include "header.h"

// Function to create a file with the values of the Syracuse sequence and additional informations at the end
void Syracuse(long u, char* FILE_NAME) {

    // We put the output file in the data directory
    char* FILE_NAME_LOCATION = malloc(strlen(FILE_NAME) + 5);
    strcpy(FILE_NAME_LOCATION, "data/");
    strcat(FILE_NAME_LOCATION, FILE_NAME);

    // We open the file with the name entered in parameter
    FILE* file = fopen(FILE_NAME_LOCATION, "w");

    // We check that the file opened properly
    if (file == NULL){
        puts ("Fichier non ouvert");
        exit (1);
    }

    // We create variables that are required for the proper functioning of the program
    long i = 0;
    long START = u;
    long MAX = u;
    long MAX_ALT_DURATION = 0;
    long COUNTER = 0;

    // Firstly, we write "n" and "Un" in the file to separate the values of the sequence
    // Then we write the first value of the sequence
    fprintf(file, "n Un\n");
    fprintf(file, "%ld %ld\n", i, u);

    // We write values in the file as long as the sequence has not reached 1
    while(u!=1) {
        i++;

        // We perform the operation every time we pass throught the loop
        if(u%2 == 0) {
            u = u/2;
        }
        else {
            u = u*3 + 1;
        }

        // We update the MAX value if necessary
        if(u>MAX) MAX = u;

        // We save the maximum duration in altitude and we update it if necessary
        if(u>START) COUNTER++;
        else {
            if(COUNTER>MAX_ALT_DURATION) MAX_ALT_DURATION = COUNTER;
            COUNTER = 0;
        }

        // Finally, we write the new value of the sequence in the file
        fprintf(file, "%ld %ld\n", i, u);
    }

    // After the loop, we write the additional informations
    fprintf(file, "altimax=%ld\n", MAX);
    fprintf(file, "dureevol=%ld\n", i);
    fprintf(file, "dureealtitude=%ld\n", MAX_ALT_DURATION);

    // We close the file after writing every necessary informations
    fclose(file);
    
}

int main(long argc, char** argv){

    // We check if the number of input parameters is correct or not
    if(argc != 3) {
        printf("Erreur : nombre de paramètres entrés invalide.\n");
        return -1;
    }

    // We check that the input value for u0 is not less than 1
    if(atoi(argv[1]) < 1) {
        printf("Erreur : Valeur de u0 inférieure à 1.\n");
        return -1;
    }

    // If there was no problem, we call the function to perform every calculations 
    Syracuse(atoi(argv[1]), argv[2]);
    
    return 0;
}