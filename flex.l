/* don't generate main() function */
%option nomain

/* don't call yywrap() at end of string */
%option noyywrap

/* 8 bit scanner */
%option 8bit

/* input is not interactive (to flex) */
%option never-interactive

/* additional start condition for UTF-8 handling */
%x UTF8                     

/* C stuff */
%{
#define ENDOFUTF8 1
#define MOREUTF8  0
#include "flextokens.h"     // token definitions
int remainingutf8bytes = 0; // remaining UTF-8 bytes
int expectedutf8bytes = 0;  // expected UTF-8 bytes
char utf8buffer[5];         // buffer for one UTF-8 character
double realvalue = 0.;      // real value if token == REAL
    
    int appendUTF8();
%}

/*digit       [0-9]
integer     {digit}+
exponant    [eE][-+]?{integer}
real        [+-]?{integer}("."{integer})?{exponant}?*/

text        [A-z]+
white       [ \t\n]+

/*dblquote     "\""([^"\""]|\\.)*("\""|.)?
sngquote     "\'"([^"\'"]|\\.)*("\'"|.)?*/
dblquote    "\""([^"\""]|\\.)*"\""
sngquote    "\'"([^"\'"]|\\.)*"\'"

linecomment "//".*
bloccomment "/*"([^"*/"]|\\(.|\n))*"*/"
htmlcomment "<!"([^">"]|\\(.|\n))*">"

variable    "$"[A-z0-9]+(;+<>=" ")?

html_tag    "<"([^">"\n]|\\.)*">"

keyword     ([A-z]|\\.)*[ (\[]?

/* definitions for UTF-8 handling */
/* see "The Unicode Standard Version 5.0", page 103 */

/* -> 2 bytes */
utf8_2      [\xC0-\xDF]
/* -> 3 bytes */
utf8_3      [\xE0-\xEF]
/* -> 4 bytes */
utf8_4      [\xF0-\xF7]
/* trailing bytes */
utf8_t      [\x80-\xBF]

%%
 /* RULES */

 /* utf8 handling rules */

<*>{utf8_2}         { BEGIN UTF8; utf8buffer[0] = *yytext; remainingutf8bytes = 1; expectedutf8bytes = 2; }
<*>{utf8_3}         { BEGIN UTF8; utf8buffer[0] = *yytext; remainingutf8bytes = 2; expectedutf8bytes = 3; }
<*>{utf8_4}         { BEGIN UTF8; utf8buffer[0] = *yytext; remainingutf8bytes = 3; expectedutf8bytes = 4; }
<UTF8>{utf8_t}      { if (appendUTF8() == ENDOFUTF8) { BEGIN INITIAL; return TEXT; }}

{text}              { return TEXT; }
{white}             { return TEXT; }
{linecomment}       { return COMMENTED; }
{bloccomment}       { return COMMENTED; }
{htmlcomment}       { return COMMENTED; }
{dblquote}          { return INSIDE_QUOTES; }
{sngquote}          { return SINGLE_INSIDE_QUOTES; }
{variable}          { return VARIABLE; }
{html_tag}          { return HTML_TAG; }
{keyword}           { return KEYWORD; }
.                   { return TEXT; }


%%
/* SUBROUTINES */
/* helper function to handle UTF-8 bytes */
int appendUTF8()
{
    // save byte to UTF-8 buffer
    utf8buffer[expectedutf8bytes - (remainingutf8bytes--)] = *yytext;
    
    // set yytext pointer to buffer at end of UTF-8 byte stream
    if (remainingutf8bytes == 0) {
        utf8buffer[expectedutf8bytes] = '\0';
        yytext = utf8buffer;
        return ENDOFUTF8;
    }
    return MOREUTF8;
}

/* reset start condition stack */
void yystatereset()
{
    BEGIN INITIAL;
}