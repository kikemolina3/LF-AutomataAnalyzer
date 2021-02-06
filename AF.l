%option noyywrap

%{
  #include "AF.tab.h"
  int estamos_alfabeto=0;
  int estamos_estado=0;
  int num_estados=0;
%}

/* DEFINICIONES */
E \ *|\t*
ALFABETO  [aA][lL][fF][aA][bB][eE][tT][oO]
ESTADOS [eE][sS][tT][aA][dD][oO][sS]
TRANSICIONES  [tT][rR][aA][nN][sS][iI][cC][iI][oO][nN][eE][sS]
INICIAL [iI][nN][iI][cC][iI][aA][lL]
FINALES [fF][iI][nN][aA][lL][eE][sS]
SIMBOLO [a-zA-Z0-9]
NUM [0-9]+
ABRIR \{
CERRAR  \}
COMENTARIO  \%.*\n
ABRIR_PARENTESIS \(
CERRAR_PARENTESIS \)
COMA \,
PC \;
%x comentario

%%
{NUM} { yylval.string = strdup(yytext);
        if(estamos_alfabeto && (strlen(yytext)==1)) return SIMBOLO;
        else return NUM;
        if(estamos_estado) num_estados++;
      }
{SIMBOLO} { yylval.string = strdup(yytext); return SIMBOLO; }
{ABRIR} { return ABRIR; }
{CERRAR} { estamos_alfabeto=0; estamos_estado=0; return CERRAR; }
{ALFABETO} { estamos_alfabeto=1; estamos_estado=0; return ALFABETO; }
{ESTADOS}   { estamos_estado=1; return ESTADOS; }
{TRANSICIONES} { return TRANSICIONES; }
{INICIAL} { return INICIAL; }
{FINALES} { return FINALES; }
{COMA} { return COMA;}
{PC} { return PC; }
{ABRIR_PARENTESIS} {return ABRIR_PARENTESIS;}
{CERRAR_PARENTESIS} {return CERRAR_PARENTESIS;}
{E}
{COMENTARIO}
. { printf("[ERROR] Input %s no contemplado.\n", yytext); yyterminate(); }
<<EOF>> { yyterminate(); }
%%
