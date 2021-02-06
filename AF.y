/* ------------------------------------------ */
/*  Practica 2 - Lenguajes Formales           */
/*  Autores:                                  */
/*    - Enrique Molina                        */
/*    - Aleix Bertran                         */
/*    - Inigo Arriazu                         */
/* ------------------------------------------ */
%token ALFABETO ESTADOS TRANSICIONES INICIAL FINALES ABRIR CERRAR COMA ABRIR_PARENTESIS CERRAR_PARENTESIS PC
%{
// INCLUSION DE LIBRERIAS
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <stdbool.h>
    #define MAX_ELEMENTS 20

// DEFINICION DE CABECERAS DE FUNCIONES
    int yylex();
    void inicializaAlfabeto();
    bool estadoValido(int num);
    void setEstados(int num);
    bool simboloExistente(char * symbol, char* list[], int length);
    bool tieneEstado(int estados);
    void appendAFD(int n1, char* symbol, int n2);
    void appendAFND(int n1, char* symbol, int n2);
    void addTransicion(int n1, char* symbol, int n2);
    bool transicionExiste(int n1, int n2, char* simb);
    bool comprobarDeterminista(int n1, char* simb);
    void crearCodigoAF();
    void final();
    void yyerror(char * msg);
    extern FILE* yyin;

// DEFINICION DE VARIABLES Y ESTRUCTURAS
    bool estamosFinales = false;
    typedef struct Transicion {
        int estadoInicial;
        int estadoFinal;
        char* simbolo;
    }Transicion;
    Transicion transiciones[MAX_ELEMENTS*MAX_ELEMENTS];
    int numTrans = 0;
    char* alfabeto[MAX_ELEMENTS];
    int numSimbolos = 0;
    int estados[MAX_ELEMENTS];
    int numEstados = 0;
    int estadoInicial;
    int finalEstados[MAX_ELEMENTS];
    int numEstFinal = 0;
    int isAFD = 1;
    char* codigoAFD = "int transicion (int estado, char simbolo) {\n\tint sig;\n";
    char* codigoAFND = "int * transicion (int estado, char simbolo) {\n\tstatic int sig[NUMESTADOS+1], n=0;\n";
    char* aux;
%}

%union {
    char *string;
};

%token <string> SIMBOLO NUM

%%

start :  alfabeto estados transiciones inicial finales
;
alfabeto : ALFABETO ABRIR simbolo CERRAR
            | ALFABETO ABRIR CERRAR { yyerror("[ERROR] El alfabeto debe contener uno o más símbolos.\n"); }
;
simbolo : simbolo COMA simbolo
            | SIMBOLO { if(!simboloExistente($1, alfabeto, numSimbolos))
                            strcpy(alfabeto[numSimbolos++], $1);
                        else
                            printf("[AVISO] El símbolo %s ya existe.\n", $1); }
;
estados : ESTADOS ABRIR NUM CERRAR {  printf("# Estados: %s\n", $3);
                                      numEstados = atoi($3);
                                      setEstados(numEstados); }
;
transiciones : TRANSICIONES ABRIR list CERRAR
;
list : transicion COMA list
            | transicion
;
transicion : ABRIR_PARENTESIS NUM COMA SIMBOLO PC NUM CERRAR_PARENTESIS { addTransicion(atoi($2), $4, atoi($6)); }
            | ABRIR_PARENTESIS NUM COMA NUM PC NUM CERRAR_PARENTESIS { addTransicion(atoi($2), $4, atoi($6)); }
;
inicial : INICIAL ABRIR NUM CERRAR {    estamosFinales = true;
                                        if(estadoValido(atoi($3))){
                                            estadoInicial = atoi($3);
                                            printf("Estado Inicial: %s\n", $3);
                                        }
                                        else
                                          yyerror("[ERROR] El estado inicial supera el limite\n"); }
            | INICIAL ABRIR num CERRAR { yyerror("[ERROR] Los Autómatas Finitos solo deben tener un estado inicial.\n"); }
            | INICIAL ABRIR CERRAR { yyerror("[ERROR] Los Autómatas Finitos solo deben tener un estado inicial.\n"); }
;
finales : FINALES ABRIR num CERRAR {  printf("El/Los estado/s final es/son: ");
                                      for(int i = 0; i < numEstFinal; i++)
                                        printf("%i ", finalEstados[i]);
                                      printf("\n");}
            | FINALES ABRIR CERRAR { yyerror("[ERROR] Los Autómatas Finitos deben tener algún estado final.\n"); }
;
num : num COMA num
            | NUM { if(estamosFinales){
                      if(!tieneEstado(atoi($1)) && estadoValido(atoi($1)))
                          finalEstados[numEstFinal++] = atoi($1);
                      else {
                          if(estadoValido(atoi($1)))
                              printf("[AVISO] El estado final %s ya existe.\n", $1);
                              else {
                                sprintf(aux, "[ERROR] El estado final %s no es válido.\n", $1);
                                yyerror(aux);
                              }
                  }}}
;
%%
/*Funcion que inicializa la lista de simbolos del lenguaje*/
void inicializaAlfabeto(){
  for (int i = 0; i < MAX_ELEMENTS; i++)
    alfabeto[i] = malloc(2);
}

/*Funcion que nos informa si un estado pertenece a nuestro sistema o no*/
bool estadoValido(int num) {
    if (num < numEstados)
      return true;
    return false;
}

/*Funcion que guarda los diferentes estados en sus estr. de datos*/
void setEstados(int num){
    for (int i = 0; i < num; i++)
      estados[i] = i;
}

/*Funcion que nos indica si un simbolo se encuentra en el alfabeto o no*/
bool simboloExistente(char * symbol, char* list[], int length){
    for (int i = 0; i < length; i++)
      if (!strcmp(list[i], symbol))
        return true;
    return false;
}

/*Funcion que nos indica si nos encontramos en un estado final*/
bool tieneEstado(int estados){
    for (int i = 0; i < numEstFinal; i++)
      if (finalEstados[i] == estados)
        return true;
    return false;
}

/*Funcion que agrega linea de codigo de AFD*/
void appendAFD(int n1, char* symbol, int n2) {
    aux = malloc(strlen(codigoAFD)+50);
    sprintf(aux, "%s\tif ((estado==%i)&&(simbolo==\'%s\')) sig=%i;\n", codigoAFD, n1, symbol, n2);
    codigoAFD = aux;
}

/*Funcion que agrega linea de codigo de AFND*/
void appendAFND(int n1, char* symbol, int n2) {
    aux = malloc(strlen(codigoAFND)+60);
    sprintf(aux, "%s\tif ((estado==%i)&&(simbolo==\'%s\')) sig[n++]=%i;\n", codigoAFND, n1, symbol, n2);
    codigoAFND = aux;
}
/*Funcion que agrega una transicion a la lista
    - o no si esta repetida*/
void addTransicion(int n1, char* symbol, int n2) {
    char* error = malloc(50);
    if(!estadoValido(n1)) {
        sprintf(error, "[ERROR] El estado %i de la transición(%i, %s; %i) es desconocido\n", n1, n1, symbol, n2);
        yyerror(error);
    }
    if(!estadoValido(n2)) {
        sprintf(error, "[ERROR] El estado %i de la transición(%i, %s; %i) es desconocido\n", n2, n1, symbol, n2);
        yyerror(error);
    }
    if(!simboloExistente(symbol, alfabeto, numSimbolos)) {
        sprintf(error, "[ERROR] El símbolo %s de la transición(%i, %s; %i) es desconocido\n", symbol, n1, symbol, n2);
        yyerror(error);
    }
    free(error);
    if (transicionExiste(n1, n2, symbol))
      printf("[AVISO] Transición (%i, %s, %i) repetida.\n", n1, symbol, n2);
    else {
      if(!comprobarDeterminista(n1, symbol)){
        if(isAFD) printf("[AVISO] Se ha detectado que el AF es no determinista.\n");
        isAFD = 0;
      }
      transiciones[numTrans].estadoInicial = n1;
      transiciones[numTrans].estadoFinal = n2;
      transiciones[numTrans].simbolo = malloc(2);
      strcpy(transiciones[numTrans].simbolo, symbol);
      numTrans++;
      appendAFD(n1, symbol, n2);
      appendAFND(n1, symbol, n2);
    }
}
/*Funcion que comprueba si una transicion ya existe*/
bool transicionExiste(int n1, int n2, char* simb) {
    for (int i = 0; i < numTrans; i++)
      if ((transiciones[i].estadoInicial == n1) && (transiciones[i].estadoFinal == n2) && (!strcmp(transiciones[i].simbolo, simb)))
        return true;
    return false;
}
/*Funcion que comprueba si una transicion tiene mismo origen y simbolo --> paara a ser AFND*/
bool comprobarDeterminista(int n1, char* simb) {
    for (int i = 0; i < numTrans; i++)
      if (transiciones[i].estadoInicial == n1 && !strcmp(transiciones[i].simbolo, simb))
        return false;
    return true;
}

/*Funcion que reporta error*/
void yyerror(char * msg){
    printf("%s", msg);
    exit(1);
}

/*Funcion que crea los ficheros de prueba del automata --> transiciones.h & transiciones..c*/
void final(){
    if (isAFD){
        aux = malloc(strlen(codigoAFD)+20);
        sprintf(aux, "%s\treturn (sig);\n}", codigoAFD);
    }
    else{
        aux = malloc(strlen(codigoAFND)+50);
        sprintf(aux, "%s\tsig[n]=-1; /*centinella*/\n\treturn (sig);\n}", codigoAFND);
    }
    printf("%s\n", aux);
    FILE* fC = fopen("transiciones.c", "wa");
    fprintf(fC, "%s", aux);
    fclose(fC);
}

int main(int argc, char **argv){
    inicializaAlfabeto();
    printf("----INICIO----\n");
    if (argc > 1)
      yyin=fopen(argv[1],"r");
    else
      yyin=stdin;
    yyparse();
    printf("----FINAL----\n\n----CODIGO CREADO EN \"transiciones.c\"----\n\n");
    final();
    return 0;
}
